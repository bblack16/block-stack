module BlockStack
  module Formatters
    module YAML
      def self.process(response, request, params)
        response.body = response.body.to_yaml
      end

      def self.mime_types
        ['text/yaml', 'application/yaml', 'application/x-yaml']
      end
    end
  end
end
