####################
# Features
####################
# Automatically convert any ruby object

module BlockStack
  class Formatter
    include BBLib::Effortless

    bridge_method :mime_type, :content_type, :format

    def self.formatters
      descendants
    end

    # Used for autodetection. If a request matches one of these mime types, this formatter is used.
    def self.mime_type
      'text/html'
      # Can also be an array like:
      # ['text/html', 'application/json']
    end

    # When passed as a param, the following is used to select this formatter
    # For example, a get route with either ".txt" or "?format=txt" would match below
    def self.format
      [:txt, :text]
    end

    # What content type this formatter will return. Can be a string or the symbol equivalent that sinatra respects (e.g. :json)
    def self.content_type
      :text
    end

    def format_match?(param)
      [format].flatten.any? { |f| f.to_s.downcase == param.to_s.downcase }
    end

    def mime_type_match?(accept)
      accept.any? { |a| [mime_type].any? { |m| m == a } }
    end

    def process(body, params = {})
      body.to_s
    end

  end
end

# Load other formatters
Dir.glob(File.expand_path('..', __FILE__) + '/*.rb').each do |file|
  next if file == __FILE__
  require_relative file
end
