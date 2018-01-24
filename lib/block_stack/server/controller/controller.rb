module BlockStack
  class Controller < Server

    def self.base_server
      @base_server
    end

    def self.base_server=(bs)
      @base_server = bs
    end

    def self.controllers
      []
    end

    def self.model
      return @model if @model
      return nil unless defined?(BlockStack::Model)
      name = self.to_s.split('::').last.sub(/Controller$/, '')
      @model = BlockStack::Model.model_for(name.method_case.to_sym)
    end

    bridge_method :model

    def self.model=(mdl)
      raise ArgumentError, "Invalid model passed to #{self}. Must be inherited from BlockStack::Model, got #{mdl}." unless mdl < BlockStack::Model
      @model = mdl
    end

    def self.crud(opts = {})
      opts[:model] = Model.model_for(opts[:model]) if opts[:model].is_a?(Symbol)
      self.model = opts[:model] if opts[:model]
      self.prefix = opts.include?(:prefix) ? opts[:prefix] : model.plural_name
      attach_route_template_group(:crud, *(opts[:ignore] || []))
      true
    end

    protected

    def method_missing(method, *args, &block)
      if base_server && base_server.respond_to?(method)
        base_server.send(method, *args, &block)
      else
        super
      end
    end

    def respond_to_missing?(method, include_private = false)
      base_server && base_server.respond_to?(method) || super
    end

    def find_model
      return nil unless model
      model.find(params[:id])
    end
  end

  Server.config(controller_base: BlockStack::Controller)
end
