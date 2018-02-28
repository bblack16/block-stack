module BlockStack
  # TODO Add better hooks to default crud methods to allow custom model
  # gathering
  add_template(:index, :crud, :get, '/', type: :route) do
    begin
      if model.config.paginate_at
        @models = model.page(params[:page] || 1)
      else
        @models = model.all
      end
      @models = process_model_index(@models) if respond_to?(:process_model_index)
      send(config.default_renderer, :"#{model.plural_name}/index")
    rescue Errno::ENOENT => _e
      @model = model
      slim :"#{settings.default_view_folder}/index"
    end
  end

  add_template(:show, :crud, :get, '/:id', type: :route) do
    begin
      @model = find_model
      @model = process_model_show(@model) if respond_to?(:process_model_show)
      if @model
        send(config.default_renderer, :"#{model.plural_name}/show")
      else
        redirect "/#{model.plural_name}", notice: "Could not locate any #{model.clean_name.pluralize} with an id of #{params[:id]}."
      end
    rescue Errno::ENOENT => _e
      slim :"#{settings.default_view_folder}/show"
    end
  end

  add_template(:create, :crud, :get, '/new', type: :route) do
    begin
      @model = model
      @model = process_model_create(@model) if respond_to?(:process_model_create)
      send(config.default_renderer, :"#{model.plural_name}/new")
    rescue Errno::ENOENT => _e
      slim :"#{settings.default_view_folder}/new"
    end
  end

  add_template(:update, :crud, :get, '/:id/edit', type: :route) do
    begin
      @model = find_model
      @model = process_model_update(@model) if respond_to?(:process_model_update)
      if @model
        send(config.default_renderer, :"#{model.plural_name}/edit")
      else
        redirect "/#{model.plural_name}", notice: "Could not locate any #{model.clean_name.pluralize} with an id of #{params[:id]}."
      end
    rescue Errno::ENOENT => _e
      slim :"#{settings.default_view_folder}/edit"
    end
  end

  add_template(:search, :crud_plus, :get, '/search', type: :route) do
    # TODO
  end
end
