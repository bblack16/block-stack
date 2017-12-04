module BlockStack
  module Encryption
    class RMD160 < Provider

    def encrypt(key)
      Digest::RMD160.hexdigest(key)
    end

    end
  end
end
