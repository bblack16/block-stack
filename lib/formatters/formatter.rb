module BlockStack
  module Formatters
    module Text
      # This method receives the request and params objects from sinatra.
      # @return [String, Object] The return of this will replace the body of the request. Generally this should be a string.
      def self.process(response, request, params)
        response.body = response.body.to_s
      end

      def self.content_type
        :txt
      end
    end
  end
end
