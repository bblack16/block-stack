module BlockStack
  module Authentication
    class ProtectedLogin < Login
      attr_of BlockStack::Encryption::Provider, :encryption, default: { type: :none }, singleton: true
      attr_str :pepper, default: nil, allow_nil: true, singleton: true
      attr_bool :random_salt, default: false, singleton: true

      attr_str :password, arg_at: 1, dformed_attributes: { type: :password }
      attr_bool :encrypted, default: false, dformed: false
      attr_str :salt, default_proc: proc { |x| x.random_salt? ? (0...10).map { (65 + rand(26)).chr }.join : nil }, allow_nil: true, dformed: false

      bridge_method :encryption, :pepper, :random_salt, :random_salt?

      before :password=, :_encrypt_password, send_args: true, modify_args: true

      def match?(name, key)
        super && self.password == encrypt_secret(key)
      end

      protected

      def encrypt_secret(pass)
        encryption.encrypt([pepper, pass, salt].compact.join)
      end

      def simple_preinit(*args)
        named = BBLib.named_args(*args)
        self.encrypted = named[:encrypted] if named.include?(:encrypted)
      end

      def _encrypt_password(pass)
        return pass if encrypted?
        self.encrypted = true
        encrypt_secret(pass)
      end

    end
  end
end
