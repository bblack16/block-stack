module BlockStack
  module Formatters
    module JSON
      def self.process(response, request, params)
        response.body = params[:pretty] ? JSON.pretty_generate(response.body) : response.body.to_json
      end

      def self.mime_types
        ['text/json', 'application/json']
      end
    end
  end
end
