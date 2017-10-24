####################
# Features
####################
# Automatically convert any ruby object

module BlockStack
  class Formatter
    include BBLib::Effortless

    bridge_method :mime_type, :content_type

    def self.formatters
      descendants
    end

    # Used for autodetection. If a request matches one of these mime types, this formatter is used.
    def self.mime_type
      'text/html'
      # Can also be an array like below
      # ['text/html', 'application/json']
    end

    # What content type this formatter will return. Can be a string or the symbol equivalent that sinatra respects (e.g. :json)
    def self.content_type
      :text
    end

    def process(body, params = {})
      body.to_s
    end

  end
end

# Load other formatters
Dir.glob(File.expand_path('../formatters', __FILE__) + '/*.rb').each do |file|
  require_relative file
end
