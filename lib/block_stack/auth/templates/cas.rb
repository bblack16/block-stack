
module BlockStack

  add_template(:cas, :block_stack_auth) do |server, opts|
    unless defined?(Rack::CAS)
      require 'rack-cas'
      require 'rack/cas'
    end
    require_relative '../helpers/cas'
    server_url = opts[:server] || opts[:server_url]
    raise ArgumentError, "You must pass a server URL (ex: server_url: 'localhost')" unless server_url
    server.helpers(BlockStack::Helpers::CAS)
    server.config(cas_login_class: BlockStack::Authentication::CASLogin)
    server.use(Rack::CAS, server_url: server_url)
    server.controllers.each do |controller|
      controller.config(cas_login_class: BlockStack::Authentication::CASLogin)
      controller.use(Rack::CAS, server_url: server_url)
      controller.helpers(BlockStack::Helpers::CAS)
    end
    server.get('/session/logout') do
      session.clear
      redirect opts[:logout_url] || "#{server_url}#{server_url.end_with?('/') ? nil : '/'}/logout"
    end
  end

end
