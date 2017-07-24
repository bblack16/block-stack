module BlockStack
  module Formatters
    class Table
      include BBLib::Effortless

      attr_hash :attributes, default: {}

      def process(response, request, params)
        payload = response.body
        rows = case [payload.class]
                when [Hash]
                  payload.squish.map { |k, v| build_row(k, v) }.join
                when [Array]
                  payload.map { |item| build_row(item) }.join
                else
                  build_row(payload)
                end
        response.body = "<table #{attributes.map { |k, v| "#{k}=\"#{v}\"" }}>#{rows}</table>"
      end

      def build_row(*values)
        '<tr>' + values.map { |value| "<td>#{value}</td>" }.join + '</tr>'
      end
    end
  end
end
