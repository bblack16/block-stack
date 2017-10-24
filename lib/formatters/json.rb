module BlockStack
  module Formatters
    class JSON < Formatter
      def self.mime_types
        ['text/json', 'application/json']
      end

      def self.content_type
        :json
      end

      def process(body, params = {})
        body.to_json
      end
    end
  end
end
