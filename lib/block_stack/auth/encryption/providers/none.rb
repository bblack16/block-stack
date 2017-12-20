module BlockStack
  module Encryption
    class None < Provider

    def encrypt(key)
      key.to_s
    end

    end
  end
end
