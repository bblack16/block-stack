module BlockStack
  module Formatters
    module YAML
      def self.process(response, request, params)
        response.body = response.body.to_yaml
      end
    end
  end
end
