module BlockStack
  module Encryption
    class MD5 < Provider

    def encrypt(key)
      Digest::MD5.hexdigest(key)
    end

    end
  end
end
