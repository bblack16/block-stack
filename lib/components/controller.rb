
module BlockStack
  class Controller < BlockStack::UiServer

    def self.model
      @model ||= BlockStack::Model.model_for(model_name)
    end

    def self.model=(klass)
      @model = klass
    end

    def self.model_name
      self.to_s.sub(/controller$/i, '').method_case.to_sym
    end

    def self.crud(custom_model = nil, opts = {})
      custom_model = model unless custom_model
      super(custom_model, opts)
    end

    def self.route_prefix
      self.to_s.split('::').last.sub(/Controller$/, '').method_case.pluralize
    end

    def self.api_route_prefix
      "api/#{route_prefix}"
    end

  end
end

BlockStack::UiServer.set(controller_base: BlockStack::Controller)
BlockStack::Controller.set(controller_base: nil)
