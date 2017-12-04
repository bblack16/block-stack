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
      name = self.to_s.sub(/Controller$/, '')
      @model = BlockStack::Model.model_for(name.method_case.to_sym)
    end

    bridge_method :model

    def self.model=(mdl)
      @model = mdl if mdl.is_a?(BlockStack::Model)
    end

    # TODO Add error message returns for save methods
    # TODO Break into several methods that are linked with crud
    def self.crud(opts = {})
      self.model = opts[:model] if opts[:model]
      self.prefix = opts.include?(:prefix) ? opts[:prefix] : model.plural_name

      # Index
      # TODO Improve default limits and offsets and add pagination
      get_api '/' do
        limit = params[:limit]&.to_i || 25
        offset = ((params[:page]&.to_i || 1) - 1) * limit
        if params[:query]
          model.search(params[:query])
        else
          model.all(limit: limit, offset: offset)
        end.map(&:serialize)
      end unless opts.include?(:index) && !opts[:index]

      # Show
      get_api '/:id' do
        item = model.find(params[:id])
        halt(404, { status: :error, message: "#{model.clean_name.capitalize} with id #{params[:id]} not found." }) unless item
        item.serialize
      end unless opts.include?(:show) && !opts[:show]

      # Create
      post_api '/' do
        begin
          args = json_request
          BlockStack.logger.info("POST #{model.clean_name} - Params #{args}")
          item = model.new(args)
          halt(404, { status: :error, message: "#{model.clean_name.capitalize} with id #{params[:id]} not found." }) unless item
          if result = item.save
            { result: result, status: :success, message: "Successfully saved #{model.model_name} #{item.id rescue nil}" }
          else
            { status: :error, message: "Failed to save #{model.model_name}" }
          end
        rescue InvalidModel => e
          { result: item.errors, status: :error, message: "Failed to save #{model.model_name}" }
        rescue => e
          { status: :error, message: "Failed to save due to the following error: #{e}" }
        end
      end unless opts.include?(:create) && !opts[:create]

      # Update
      put_api '/:id' do
        begin
          args = json_request
          BlockStack.logger.info("Update #{model.clean_name} #{params[:id]} - Params #{args}")
          item = model.find(params[:id])
          halt(404, { status: :error, message: "#{model.clean_name.capitalize} with id #{params[:id]} not found." }) unless item
          if result = item.update(args)
            { result: result, status: :success, message: "Successfully saved #{model.model_name} #{item.id rescue nil}" }
          else
            { result: result, status: :error, message: "Failed to save #{model.model_name}" }
          end
        rescue => e
          BlockStack.logger.error(e)
          halt(500, { result: nil, status: :error, message: 'Failed to update item. Check the logs for errors.' })
        end
      end unless opts.include?(:update) && !opts[:update]

      # Delete
      delete_api '/:id' do
        item = model.find(params[:id])
        halt(404, { status: :error, message: "#{model.clean_name.capitalize} with id #{params[:id]} not found." }) unless item
        if response = item.delete
          { status: :success, result: response }
        else
          { status: :error, result: response }
        end
      end unless opts.include?(:delete) && !opts[:delete]

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
  end
end
