module BlockStack
  module Encryption
    class SHA2 < Provider
    BITS = [256, 384, 512].freeze

    attr_element_of BITS, :bits, default: BITS.first

    def encrypt(key)
      case bits
      when 256
        Digest::SHA256
      when 384
        Digest::SHA384
      when 512
        Digest::SHA512
      end.hexdigest(key)
    end

    end
  end
end
