module BlockStack
  module Formatters
    class JSON < Formatter
      def self.mime_types
        ['text/json', 'application/json']
      end

      def self.content_type
        :json
      end

      def self.format
        :json
      end

      def process(body, params = {})
        body = { data: body } unless BBLib.is_a?(body, Array, Hash)
        params.include?(:pretty) ? ::JSON.pretty_generate(body) : body.to_json
      end
    end
  end
end
