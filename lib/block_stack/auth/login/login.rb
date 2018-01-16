require_relative 'role'

module BlockStack
  module Authentication
    class Login
      include BBLib::Effortless
      attr_int :expiration, default: nil, allow_nil: true, singleton: true, pre_proc: proc { |x| x.is_a?(String) || x.is_a?(Symbol) ? x.to_s.parse_duration : x }

      attr_str :name, required: true, arg_at: 0
      attr_str :display_name, default_proc: proc { |x| x.name }
      attr_time :last_login, default: nil, allow_nil: true, dformed: false
      attr_int :login_count, default: 0, dformed: false
      attr_time :current_login, default: nil, allow_nil: true, dformed: false
      attr_ary_of Role, :roles, add_rem: true, dformed: false

      bridge_method :expiration

      def match?(name, secret = nil)
        self.name == name.to_s
      end

      # Returns true if this login has the specified role (by name or Role)
      def role?(name)
        roles.any? { |role| role == name || role.name == name.to_s.to_sym }
      end

      # Returns true if this model has expiration set, this login is active and
      # the current login is older than the expiration period.
      def expired?
        return true unless current_login
        return false unless expiration
        Time.now - self.class.expiration > current_login
      end

      def logged_in?
        current_login ? expired? : false
      end

      def logged_out?
        !logged_in?
      end

      # Can be called to quickly set various login trackers
      def log_in
        self.last_login = current_login if current_login
        self.current_login = Time.now
        self.login_count += 1
        save
      end

      # Can be called to remove the current login to invalidate it
      def log_out
        self.last_login = current_login if current_login
        self.current_login = nil
        save
      end

      # Implemented so that even if this class is not serialized to a database
      # it can still respond to save.
      def save
        if defined?(BlockStack::Model) && self.is_a?(BlockStack::Model)
          super
        else
          true
        end
      end

      protected

      def simple_init(*args)
        self.current_login = Time.now
      end

    end
  end

  load_all(File.expand_path('../types', __FILE__))
end
