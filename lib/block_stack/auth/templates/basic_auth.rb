
module BlockStack

  add_template(:basic_auth, :block_stack_auth) do |server, opts|
    server.set(:unauthorized_message, (opts[:unauthorized_message].to_s || 'Not Authorized!') + "\n")
    server.helpers(BlockStack::Helpers::BasicAuth)
    server.add_auth_source(BlockStack::Authentication::Basic.new)
    if opts[:providers]
      [opts[:providers]].flatten.each do |provider|
        provider = BlockStack::Authentication::Provider.new(provider) unless provider.is_a?(BlockStack::Authentication::Provider)
        server.add_auth_provider(provider)
      end
    end
  end

end
