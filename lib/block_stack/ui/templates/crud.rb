module BlockStack

  add_route_template(:index, :get, '/', :crud) do
    begin
      @models = model.all
      send(default_renderer, :"#{model.plural_name}/index")
    rescue Errno::ENOENT => e
      @model = model
      @models = model.all
      slim :"#{settings.default_view_folder}/index"
    end
  end

  add_route_template(:show, :get, '/:id', :crud) do
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

  add_route_template(:create, :get, '/new', :crud) do
    begin
      @model = model
      send(default_renderer, :"#{model.plural_name}/new")
    rescue Errno::ENOENT => e
      slim :"#{settings.default_view_folder}/new"
    end
  end

  add_route_template(:update, :get, '/:id/edit', :crud) do
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

  add_route_template(:search, :get, '/search', :crud_plus) do
    # TODO
  end
end
