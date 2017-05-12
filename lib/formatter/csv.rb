module BlockStack
  module Formatters
    module CSV
      def self.process(response, request, params)
        payload = response.body
        delimiter = params[:format].to_sym == :tsv ? "\t" : ","
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
        headers.map { |header| "\"#{header.to_s.gsub('"', '\\"')}\"" }.join(delimiter) + "\n" +
        response.body = content.map do |row|
          row.map do |value|
            "\"#{value.to_s.gsub('"', '\\"')}\""
          end.join(delimiter)
        end.join("\n")
      end
    end
  end
end
