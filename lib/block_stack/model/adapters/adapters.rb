module BlockStack
  module Adapters

    def self.adapters
      @adapters ||= []
    end

    def self.register(adapter)
      if adapter.respond_to?(:type)
        adapters << adapter unless adapters.include?(adapter)
        true
      else
        raise ArgumentError, "Invalid adapter #{adapter}. Must respond to :type."
      end
    end

    def self.by_type(type)
      adapters.find do |m|
        [m.type].flatten.include?(type)
      end
    end

    def self.by_client(client)
      adapters.find do |a|
        next unless a.respond_to?(:client)
        [a.client].flatten.include?(client.to_s)
      end
    end

  end
end

# Load adapters
Dir.glob(File.expand_path('..', __FILE__) + '/*.rb').each do |file|
  next if file == __FILE__
  require_relative file
end
