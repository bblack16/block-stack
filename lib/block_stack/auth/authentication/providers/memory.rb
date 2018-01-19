module BlockStack
  module Authentication
    class Memory < Provider
      attr_of Object, :login_class, default: BlockStack::Authentication::ProtectedLogin
      attr_ary_of Login, :logins, default: [], add_rem: true, adder_name: 'add_login', remover_name: 'remove_login', pre_proc: :convert_login

      def authenticate(id, secret = nil, request: {}, params: {})
        logins.each do |login|
          next unless login.match?(id, secret)
          return login
        end
        nil
      end

      protected

      def convert_login(logins)
        [logins].flatten.map do |login|
          login.is_a?(Login) ? login : login_class.new(login)
        end
      end

    end
  end
end
