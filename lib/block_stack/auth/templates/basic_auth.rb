
module BlockStack

  add_template(:basic_auth, :block_stack_auth) do |server, opts|
    server.set(:unauthorized_message, (opts[:unauthorized_message].to_s || 'Not Authorized!') + "\n")
    server.helpers(BlockStack::Helpers::BasicAuth)
    server.add_auth_sources(BlockStack::Authentication::Basic.new)
    # server.add_auth_providers(BlockStack::)
  end

end
