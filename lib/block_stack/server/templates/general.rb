module BlockStack

  add_route_template(:welcome, :get_api, '/', :block_stack) do
    {
      message: 'Welcome to BlockStack!',
      application: self.class.to_s,
      time: Time.now,
      verion: BlockStack::VERSION,
      ruby: RUBY_VERSION,
      os: BBLib::OS.os
    }
  end

  add_route_template(:routes, :get_api, '/routes', :block_stack) do
    self.class.route_map
  end

  add_route_template(:time, :get_api, '/time', :block_stack) do
    { time: params[:time_format] ? Time.now.strftime(params[:time_format]) : Time.now.to_f }
  end
end
