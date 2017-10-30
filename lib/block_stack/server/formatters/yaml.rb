module BlockStack
  module Formatters
    class YAML < Formatter
      def self.mime_types
        ['text/yaml', 'application/yaml', 'application/x-yaml']
      end

      def self.content_type
        :yaml
      end

      def self.format
        [:yaml, :yml]
      end

      def process(body, params = {})
        body.to_yaml
      end
    end
  end
end
