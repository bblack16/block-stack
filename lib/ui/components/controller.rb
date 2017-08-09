module BlockStack
  class Controller < BlockStack::UiServer

    def self._model
      @model ||= Model.model_for(_model_name)
    end

    def self._model=(klass)
      @model = klass
    end

    def self._model_name
      self.to_s.sub(/controller$/i, '')
    end
  end
end

BlockStack::UiServer.set(controller_base: BlockStack::Controller)
