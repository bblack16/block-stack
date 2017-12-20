module BlockStack
  module Authentication
    class Provider
      include BBLib::Effortless
      attr_of Object, :login_class, default: BlockStack::Authentication::Login

      setup_init_foundation(:type)

      def self.type
        self.to_s.split('::').last.method_case.to_sym
      end

      bridge_method :type

      # Should be overwritten in sublcasses.
      # Must return a user object if the request can be validated, otherwise
      # nil or false should be returned (indicating a failed authentication).
      def authenticate(id, secret = nil, request: {}, params: {})
        build_user(name: id)
      end

      # Similar to :authenticate but only returns true or false and not a user
      # object.
      def authenticate?(*args)
        authenticate(*args).is_a?(user_class) ? true : false
      end

      # This can be overwritten in subclasses where users can be added to the provider.
      # This should return the user object if successful, otherwise nil or false.
      def add_user(id, secret = nil, **attributes)
        nil
      end

      protected

      def simple_preinit(*args)
        named = BBLib.named_args(*args)
        self.login_class = named[:login_class] if named[:login_class]
      end

      def build_user(*args)
        login_class.new(*args)
      end

    end
  end

  load_all(File.expand_path('../providers', __FILE__))
end
