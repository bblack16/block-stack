module BlockStack
  module ControllerUtil

    def self.included(base)
      base.extend(ClassMethods)
    end

    def model
      self.class.model
    end

    module ClassMethods
      def model
        @model ||= BlockStack::Model.model_for(model_name)
      end

      def model=(klass)
        @model = klass
      end

      def model_name
        self.to_s.split('::').last.sub(/controller$/i, '').method_case.to_sym
      end

      def route_prefix
        self.to_s.split('::').last.sub(/Controller$/, '').method_case.pluralize
      end

      def api_route_prefix
        "api/#{route_prefix}"
      end

      def base_server(server = nil)
        @base_server = server if server
        @base_server
      end
    end
  end
end
