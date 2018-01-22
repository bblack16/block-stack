
module BlockStack

  add_template(:login, :block_stack_user_auth, :get, '/login', type: :route) do
    if current_login
      redirect server.config.homepage || '/', 303
    else
      slim :'default/login'
    end
  end

  add_template(:login_session, :block_stack_user_auth, :post_api, '/session/login', type: :route) do
    protected!
    if current_login
      redirect config.homepage, 303, notice: "Hello and welcome, #{current_user.display_name}!"
    else
      redirect config.login_page, 303
    end
  end

  add_template(:logout, :block_stack_user_auth, :get, '/session/logout', type: :route) do
    name = current_login.display_name
    logout
    redirect '/login', 303, notice: "Goodbye, #{name}."
  end

  add_template(:register, :block_stack_user_auth, :post_api, '/session/register', type: :route) do
    user = JSON.parse(request.body.read).keys_to_sym
    begin
      u = config.login_model.new(user)
      if result = u.save
        { result: result, status: :success, message: "Registration completed successfully." }
      else
        { status: :error, message: "Registration failed." }
      end
    rescue BlockStack::Model::InvalidModelError => e
      { result: item.errors, status: :error, message: "Registration failed." }
    rescue => e
      { status: :error, message: "Registration failed: #{e}" }
    end
  end

  add_template(:user_auth, :block_stack_auth) do |server, opts|

    server.config(
      homepage:           opts[:homepage] || '/',
      login_page:         opts[:login_page] || '/login',
      allow_registration: opts[:allow_registration],
      login_model:        opts[:login_model] || opts[:user_model] || BlockStack::Authentication::User
    )

    auth_sources = opts[:auth_sources] || [BlockStack::Authentication::HTMLForm.new, BlockStack::Authentication::Basic.new]

    server.add_auth_source(*auth_sources)
    server.skip_auth(server.config.login_page, '/session/register')
    server.helpers(BlockStack::Helpers::UserAuth)
    server.attach_template_group(:block_stack_user_auth)

    if opts[:providers]
      [opts[:providers]].flatten.each do |provider|
        provider = BlockStack::Authentication::Provider.new(provider) unless provider.is_a?(BlockStack::Authentication::Provider)
        server.add_auth_provider(provider)
      end
    end
  end

  add_template(:database_auth, :block_stack_auth) do |server, opts|
    attach_template(:user_auth, :block_stack_auth)
    server.config(allow_registration: !opts.include?(:allow_registration) || opts[:allow_registration])

    server.config.user_model.send(:include, BlockStack::Model::Dynamic()) unless server.config.user_model.is_a?(BlockStack::Model)
    server.add_auth_provider(BlockStack::Authentication::Database.new(login_class: user_model))
  end

end
