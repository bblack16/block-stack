module BlockStack
  module Formatters
    module XML
      def self.process(response, request, params)
        payload = clean_values(response.body)
        if payload.is_a?(Array)
          payload = { responses: { response: payload } }
        else
          payload = { response: payload }
        end
        response.body = '<?xml version="1.0" encoding="UTF-8"?>' + Gyoku.xml(payload, pretty_print: params.include?('pretty'), key_converter: proc { |key| key.to_s.title_case.drop_symbols })
      end

      def self.clean_values(payload)
        case [payload.class]
        when [Array]
          payload.map { |elem| clean_values(elem) }
        when [Hash]
          payload.hmap { |k, v| [clean_values(k).title_case.gsub('_', ''), clean_values(v)] }
        when [String], [Integer], [Fixnum], [Float], [TrueClass], [FalseClass]
          payload
        else
          payload.to_s
        end
      end

      def self.mime_types
        ['text/xml', 'application/xml']
      end
    end
  end
end
