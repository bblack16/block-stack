module BlockStack
  module Formatters
    module CSV
      def self.process(response, request, params)
        payload = response.body
        delimiter = params[:format].to_s.to_sym == :tsv ? "\t" : ","
        if payload.is_a?(Hash)
          headers = payload.keys
          content = [payload.values]
        elsif payload.is_a?(Array)
          if payload.all? { |elem| elem.is_a?(Hash) }
            headers = payload.flat_map(&:keys).uniq
            content = payload.map do |row|
              headers.map { |header| row[header].to_s }
            end
          else
            headers = ['']
            content = [payload.map(&:to_s)]
          end
        else
          headers = ['']
          content = [[payload.to_s]]
        end
        header_row = headers.map { |header| "\"#{header.to_s.gsub('"', '\\"')}\"" }.join(delimiter) + "\n"
        rows = content.map do |row|
          row.map do |value|
            "\"#{value.to_s.gsub('"', '\\"')}\""
          end.join(delimiter)
        end.join("\n")
        response.body = header_row + rows
      end

      def self.mime_types
        ['text/csv', 'text/tsv']
      end
    end
  end
end
