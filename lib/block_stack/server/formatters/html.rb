module BlockStack
  module Formatters
    class HTML < Formatter
      def self.mime_types
        'text/html'
      end

      def self.format
        :html
      end

      def self.content_type
        :html
      end
    end
  end
end
