module BlockStack
  module Authentication
    class Database < Provider
      attr_of Class, :user_model

      def authenticate(id, secret, request = {}, params = {})
        matches = users(id)
        return false if matches.empty?
        matches.find do |user|
          user.password == encrypt_key(secret)
        end
      end

      def add_user(id, secret, **attributes)
        user = user_model.new(attributes.merge(name: user, password: encrypt_key(secret)))
        user.save ? user : nil
      end

      def users(name)
        user_model.find_all(name: name)
      end

      # TODO Support other digest encrpytion methods by symbol
      def encrypt_key(key)
        return key.to_s unless user_model.encrypt_password
        BlockStack::Encryption.encrypt(key, user_model.encrypt_password)
      end

    end
  end
end
