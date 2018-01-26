module BlockStack
  module Authentication
    class CASLogin < Login
      attr_str :ticket
      attr_hash :extra_attributes, pre_proc: :process_extra_attributes

      init_type :loose

      def method_missing(method, *args, &block)
        extra_attributes.include?(method) ? extra_attributes[method] : super
      end

      def respond_to_missing(method, include_private = false)
        extra_attributes.include?(method) || super
      end

      protected

      def process_extra_attributes(hash)
        hash.kmap do |key|
          key.method_case.to_sym
        end
      end

    end
  end
end
