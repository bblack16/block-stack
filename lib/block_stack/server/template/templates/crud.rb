module BlockStack

  add_template(:index_api, :crud, :get_api, '/', type: :route) do
    limit = params[:limit]&.to_i || 25
    offset = ((params[:page]&.to_i || 1) - 1) * limit
    if params[:query]
      model.search(params[:query])
    else
      model.all(limit: limit, offset: offset)
    end.map(&:serialize)
  end

  add_template(:show_api, :crud, :get_api, '/:id', type: :route) do
    item = model.find(params[:id])
    halt(404, { status: :error, message: "#{model.clean_name.capitalize} with id #{params[:id]} not found." }) unless item
    item.serialize
  end

  # TODO Add error message returns for save methods
  add_template(:create_api, :crud, :post_api, '/', type: :route) do
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
      { result: item.errors, status: :error, message: "There are missing or invalid fields in this #{model.model_name}" }
    rescue => e
      { status: :error, message: "Failed to save due to the following error: #{e}" }
    end
  end

  # TODO Add error message returns for save methods
  add_template(:update_api, :crud, :put_api, '/:id', type: :route) do
    begin
      args = json_request
      BlockStack.logger.info("Update #{model.clean_name} #{params[:id]} - Params #{args}")
      item = model.find(params[:id])
      halt(404, { status: :error, message: "#{model.clean_name.capitalize} with id #{params[:id]} not found." }) unless item
      if result = item.update(args)
        { result: result, status: :success, message: "Successfully saved #{model.model_name} #{item.id rescue nil}" }
      else
        { result: result, status: :error, message: "There are missing or invalid fields in this #{model.model_name}" }
      end
    rescue InvalidModel => e
      { result: item.errors, status: :error, message: "Failed to save #{model.model_name}" }
    rescue => e
      BlockStack.logger.error(e)
      halt(500, { result: nil, status: :error, message: 'Failed to update item. Check the logs for errors.' })
    end
  end

  # TODO Add error message returns for save methods
  add_template(:delete_api, :crud, :delete_api, '/:id', type: :route) do
    item = model.find(params[:id])
    halt(404, { status: :error, message: "#{model.clean_name.capitalize} with id #{params[:id]} not found." }) unless item
    if response = item.delete
      { status: :success, result: response }
    else
      { status: :error, result: response }
    end
  end

  add_template(:search_api, :crud_plus, :get_api, '/search', type: :route) do
    # TODO
  end
end
