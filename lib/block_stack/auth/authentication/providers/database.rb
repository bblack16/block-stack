module BlockStack
  module Authentication
    class Database < Provider

      def authenticate(id, secret = nil, request: {}, params: {})
        users(id).find do |user|
          user.password?(secret)
        end
      end

      def add_user(id, secret, **attributes)
        user = user_model.new(attributes.merge(name: user, password: encrypt_key(secret)))
        user.save ? user : nil
      end

      def users(name)
        login_class.find_all(name: name)
      end
    end
  end
end
