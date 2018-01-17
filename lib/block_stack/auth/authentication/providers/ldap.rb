# This provider never authenticates a user no matter what. It is only useful
# for certain testing scenarios.
module BlockStack
  module Authentication
    class LDAP < Provider
      ENCRYPTION_TYPES = [:simple_tls, :start_tls].freeze
      AUTH_METHODS = [:anonymous, :simple].freeze
      DEFAULT_ATTRIBUTES = {
        mail:              :email,
        telephonenumber:   :phone,
        displayname:       :fullname,
        memberof:          :member_of,
        distinguishedname: :dn,
        company:           :company,
        description:       :description,
        department:        :department,
        title:             :title,
        manager:           :manager,
        l:                 :location
      }.freeze

      attr_str :host, default: 'localhost'
      attr_int :port, default: 389
      attr_str :base
      attr_element_of ENCRYPTION_TYPES, :encryption, default: ENCRYPTION_TYPES.first
      attr_element_of AUTH_METHODS, :auth_method, default: AUTH_METHODS.first
      attr_str :username, :password, allow_nil: true, default: nil
      attr_int :connection_timeout, default: 5, allow_nil: true
      attr_of Object, :instrumentation_service, default: nil, allow_nil: true
      attr_bool :force_no_page, default: false
      attr_str :auth_attribute, default: 'sAMAccountName'
      attr_bool :lookup_attributes, default: true
      attr_hash :attributes, keys: [Symbol], values: [Symbol, String], default: DEFAULT_ATTRIBUTES, pre_proc: proc { |x| x.is_a?(Array) ? x.hmap { |v| [v.to_sym, v.to_sym] } : x.keys_to_sym }
      attr_of Object, :login_class, default: BlockStack::Authentication::LDAPLogin
      attr_str :domain, allow_nil: true, default: nil
      attr_of Proc, :login_format, default: nil, allow_nil: true

      after :username=, :password=, :change_auth_method

      # Attempt to authenticate the user via our LDAP connection
      def authenticate(id, secret = nil, request: {}, params: {})
        if secret && !secret.to_s.strip.empty? && bind(process_user_login(id), secret)
          BlockStack.logger.debug("LDAP #{name}: SUCCESS - Authentication of user #{id} successful.")
          build_user(id)
        else
          BlockStack.logger.info("LDAP #{name}: DENIED - Authentication of user #{id} failed.")
          false
        end
      end

      def build_user(name)
        login_class.new(name: name).tap do |user|
          return user unless lookup_attributes?
          retrieve_attributes(name).each do |k, v|
            user.send("#{k}=", v) if user.respond_to?("#{k}=")
          end
        end
      end

      def process_user_login(name)
        if login_format
          login_format.call(name)
        else
          [name, domain].compact.join('@')
        end
      end

      # Grab the predefinied attributes for this user and add them to the login
      def retrieve_attributes(user)
        filter = Net::LDAP::Filter.contains(auth_attribute, user)
        info   = {} # Used to store attributes on first matching user
        connection.search(base: base, filter: filter, attributes: attributes.keys) do |entry|
          entry.each do |attribute, values|
            next unless attributes.include?(attribute.to_sym)
            info[attributes[attribute].to_sym] = values.size > 1 ? values.map(&:to_s) : values.first.to_s
          end
          return info
        end
      end

      def bind(*args)
        connection(*args).bind
      rescue => e
        BlockStack.logger.warn("Failed to bind LDAP connection using provider #{name}. Error follows.")
        BlockStack.logger.error(e)
        false
      end

      # Returns a new LDAP connection
      def connection(user = nil, pass = nil)
        require 'net/ldap' unless defined?(Net::LDAP)

        # Generate arguments for ldap connection
        args = {
          host:                    host,
          port:                    port,
          base:                    base,
          encryption:              encryption,
          connection_timeout:      connection_timeout,
          force_no_page:           force_no_page?,
          instrumentation_service: instrumentation_service,
          auth:                    auth_method == :anonymous ? { method: :anonymous } : { method: auth_method, username: user || username, password: pass || password }
        }.reject { |_k, v| v.nil? }

        # Build LDAP connection
        Net::LDAP.new(args)
      rescue => e
        BlockStack.logger.warn("Failed to build LDAP connection using provider #{name}. Error follows.")
        BlockStack.logger.error(e)
      end

      protected

      def change_auth_method
        self.auth_method = username || password ? :simple : :anonymous
      end

    end
  end
end
