module BlockStack
  module Formatters
    # TODO Added download support for csv files
    class CSV < Formatter

      def delimiter
        ','
      end

      def self.mime_types
        'text/csv'
      end

      def self.format
        :csv
      end

      def self.content_type
        :csv
      end

      def process(body, params = {})
        build_csv(body)
      end

      def build_csv(data)
        columns = [:data]
        content = [data]
        case data
        when Array
          if data.all? { |d| d.is_a?(Hash) }
            columns = data.map(&:keys).uniq
            content = data.map do |line|
              columns.map { |h| line[h] }
            end
          end
        when Hash
          columns = data.keys
          content = data.values
        end
        content = [content] unless content.is_a?(Array) && content.all? { |c| c.is_a?(Array) }
        header = columns.map { |col| "\"#{col.to_s.gsub('"', '\\"')}\"" }.join(delimiter) + "\n"
        rows = content.map do |row|
          row.map { |value| "\"#{value.to_s.gsub('"', '\\"')}\"" }.join(delimiter)
        end.join("\n")
        header + rows
      end
    end

    class TSV < CSV

      def delimiter
        "\t"
      end

      def self.mime_type
        'text/tsv'
      end

      def self.content_type
        :tsv
      end
    end
  end
end
