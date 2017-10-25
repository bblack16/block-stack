
module BlockStack
  class Controller < BlockStack::UiServer
    include ControllerUtil

    def self.crud(custom_model = nil, opts = {})
      custom_model = model unless custom_model
      super(custom_model, opts)
    end
  end
end

BlockStack::Server.set(controller_base: BlockStack::Controller)
BlockStack::Controller.set(controller_base: nil)
