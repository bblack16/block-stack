module BlockStack

  add_template(:welcome, :block_stack, :get_api, '/', type: :route) do
    {
      message: 'Welcome to BlockStack!',
      application: self.class.to_s,
      time: Time.now,
      verion: BlockStack::VERSION,
      ruby: RUBY_VERSION,
      os: BBLib::OS.os
    }
  end

  add_template(:routes, :block_stack, :get_api, '/routes', type: :route) do
    self.class.route_map
  end

  add_template(:time, :block_stack, :get_api, '/time', type: :route) do
    { time: params[:time_format] ? Time.now.strftime(params[:time_format]) : Time.now.to_f }
  end
end
