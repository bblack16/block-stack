require_relative 'memory'

module BlockStack
  module Authentication
    class Config < Memory
      TYPES = [:auto, :yaml, :json, :xml]

      attr_file :file, required: true
      attr_element_of TYPES, :type, default: :auto
      attr_str :path, default: 'users', allow_nil: true
      attr_bool :already_encrypted, default: false

      after :file=, :reload_config

      protected

      def simple_preinit(*args)
        named = BBLib.named_args(*args)
        self.already_encrypted = named[:already_encrypted]
      end

      def reload_config
        hash = case get_type
        when :yaml
          YAML.load_file(file)
        when :json
          JSON.parse(File.read(file))
        when :xml
          # TODO Implement XML somehow
          raise RuntimeError, 'XML is not yet supported...'
        else
          raise RuntimeError, "Unknown config type, cannot load: #{file}"
        end.keys_to_sym
        hash = hash.hpath(path).first if path
        hash.each do |user|
          add_user(user.merge(encrypted: already_encrypted?))
        end
      end

      def get_type
        return type unless type == :auto
        case File.extname(file).downcase[1..-1]
        when 'yml', 'yaml'
          :yaml
        when 'json'
          :json
        when 'xml'
          :xml
        else
          nil
        end
      end

    end
  end
end
