module BlockStack

  add_template(:index, :crud, :get, '/', type: :route) do
    begin
      @models = model.all
      @models = process_model_index(@models) if respond_to?(:process_model_index)
      send(config.default_renderer, :"#{model.plural_name}/index")
    rescue Errno::ENOENT => e
      @model = model
      @models = model.all
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
    rescue Errno::ENOENT => e
      slim :"#{settings.default_view_folder}/show"
    end
  end

  add_template(:create, :crud, :get, '/new', type: :route) do
    begin
      @model = model
      @model = process_model_create(@model) if respond_to?(:process_model_create)
      send(config.default_renderer, :"#{model.plural_name}/new")
    rescue Errno::ENOENT => e
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
    rescue Errno::ENOENT => e
      slim :"#{settings.default_view_folder}/edit"
    end
  end

  add_template(:search, :crud_plus, :get, '/search', type: :route) do
    # TODO
  end
end
