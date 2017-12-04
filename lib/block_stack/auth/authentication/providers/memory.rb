module BlockStack
  module Authentication
    class Memory < Provider
      attr_hash :users, key: String, value: Hash, default: {}
      attr_of [Symbol, Proc], :encryption_method, default: :sha256
      attr_bool :encrypt, default: true

      require 'digest' unless defined?(Digest)

      def authenticate(id, secret, request = {}, params = {})
        return false unless user?(id.to_s)
        user = user(id.to_s)
        return false unless encrypt_key(secret) == user[:password]
        build_user(user.merge(name: id.to_s))
      end

      def add_user(user, password = nil, **details)
        details[:password] = password if password
        raise ArgumentError, 'You cannot add a user without a password' unless details[:password]
        users[user.to_s] = details.merge(password: encrypt_key(details[:password]))
      end

      def users=(hash)
        (@users ||= {}).clear
        hash.each do |k, v|
          add_user(k, **v)
        end
      end

      def user?(name)
        user(name) ? true : false
      end

      def user(name)
        users[name]
      end

      # TODO Support other digest encrpytion methods by symbol
      def encrypt_key(key)
        return key.to_s unless encrypt?
        case encryption_method
        when Symbol
          Digest::SHA256.hexdigest(key.to_s)
        else
          encryption_method.call(key.to_s)
        end
      end

    end
  end
end
