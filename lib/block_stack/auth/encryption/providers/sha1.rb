module BlockStack
  module Encryption
    class SHA1 < Provider

    def encrypt(key)
      Digest::SHA1.hexdigest(key)
    end

    end
  end
end
