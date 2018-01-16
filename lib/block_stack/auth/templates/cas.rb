
module BlockStack

  add_template(:cas, :block_stack_auth) do |server, opts|
    unless defined?(Rack::CAS)
      require 'rack-cas'
      require 'rack/cas'
    end
    require_relative '../helpers/cas'
    raise ArgumentError, "You must pass a server URL (ex: server_url: 'localhost')" unless opts[:server] || opts[:server_url]
    server.helpers(BlockStack::Helpers::CAS)
    server.config(cas_login_class: BlockStack::Authentication::CASLogin)
    server.use(Rack::CAS, server_url: opts[:server] || opts[:server_url])
  end

end
