require_relative 'cached_request'

module BlockStack
  class Cache
    include BBLib::Effortless

    attr_hash :cached_requests
    attr_int :cache_limit, default: 200
    attr_int :default_ttl, default: 120
    attr_of BBLib::TaskTimer, :timer, default: BBLib::TaskTimer.new

    def add(adapter, request, result, ttl = default_ttl)
      return if result.nil? || result.respond_to?(:empty?) && result.empty?
      self.cached_requests[adapter] = [] unless self.cached_requests[adapter]
      self.cached_requests[adapter] << CachedRequest.new(adapter: adapter, request: request, result: result, ttl: ttl)
    end

    def retrieve(adapter, request = {})
      puts "REQUEST: #{request}"
      return unless cached_requests[adapter]
      timer.start(adapter)
      result = cached_requests[adapter].find { |obj| obj.match?(adapter, request) }
      timer.stop(adapter)
      BlockStack.logger.debug("(#{timer.last(adapter)}s) Loaded request from cache for #{adapter}: #{request}") if result
      result
    end

    def clean_cache
      cached_requests.keys.each do |adapter|
        cached_requests[adapter].delete_if(&:expired?)
      end
    end

    def clear_cache(adapter = nil)
      if adapter
        cached_requests[adapter].clear if cached_requests[adapter]
      else
        cached_requests.clear
      end
    end

    def self.prototype
      @prototype ||= self.new
    end

    def self.method_missing(method, *args, &block)
      prototype.respond_to?(method) ? prototype.send(method, *args, &block) : super
    end

    def self.respond_to_missing?(method, include_private = false)
      prototype.respond_to?(method) || super
    end

  end
end
