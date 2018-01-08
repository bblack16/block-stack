module BlockStack
  class Cache
    class CachedRequest
      include BBLib::Effortless

      attr_sym :adapter
      attr_of Object, :request
      attr_of Object, :result
      attr_int :ttl
      attr_time :created, default_proc: proc { Time.now }

      def expired?
        Time.now - created > ttl
      end

      def match?(adapter, request)
        # puts self.adapter
        # puts adapter
        # puts self.request.to_yaml
        # puts self.request
        # puts request
        raise "crash me" if caller.length > 500
        self.adapter == adapter && self.request == request
      end

    end
  end
end
