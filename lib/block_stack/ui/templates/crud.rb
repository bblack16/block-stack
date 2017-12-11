module BlockStack

  add_template(:index, :crud, :get, '/', type: :route) do
    begin
      @models = model.all
      send(default_renderer, :"#{model.plural_name}/index")
    rescue Errno::ENOENT => e
      @model = model
      @models = model.all
      slim :"#{settings.default_view_folder}/index"
    end
  end

  add_template(:show, :crud, :get, '/:id', type: :route) do
    begin
      @model = model.find(params[:id])
      if @model
        send(default_renderer, :"#{model.plural_name}/show")
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
      send(default_renderer, :"#{model.plural_name}/new")
    rescue Errno::ENOENT => e
      slim :"#{settings.default_view_folder}/new"
    end
  end

  add_template(:update, :crud, :get, '/:id/edit', type: :route) do
    begin
      @model = model.find(params[:id])
      if @model
        send(default_renderer, :"#{model.plural_name}/edit")
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
