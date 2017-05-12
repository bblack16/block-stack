module BlockStack
  module Formatters
    module YAML
      def self.process(response, request, params)
        payload = response.body
        case [payload.class]
        when [Hash]

        when [Array]

        else

        end
      end

      def self.build_row

      end
    end
  end
end
