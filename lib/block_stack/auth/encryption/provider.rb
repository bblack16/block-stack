module BlockStack
  module Encryption
    class Provider
      include BBLib::Effortless

      setup_init_foundation :type

      def self.type
        self.to_s.split('::').last.downcase.to_sym
      end

      bridge_method :type

      # This should be overrwritten in all subclasses. The default here only
      # reverses the key as an example and should NEVER be used for secure
      # encryption; it is for example purposes only.
      def encrypt(key)
        key.to_s.reverse
      end

      # For the most part this should never ACTUALLY decrypt but is provided
      # as a hook in case it is useful in custom algorithms.
      def decrypt(key)
        key
      end

      # The default match? simply encrypts one key and compares it to an
      # already encrypted key. If they match, true is returned.
      def match?(key, encrypted)
        encrypt(key) == encrypted
      end

    end

  end
  load_all(File.expand_path('../providers', __FILE__))
end
