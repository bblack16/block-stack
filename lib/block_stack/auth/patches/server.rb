module BlockStack
  class Server
    enable :sessions

    attr_ary_of Authentication::Source, :auth_sources, default: [], singleton: true, add_rem: true, adder_name: 'add_auth_source', remover_name: 'remove_auth_source'
    attr_ary_of Authentication::Provider, :auth_providers, default: [], singleton: true, add_rem: true, adder_name: 'add_auth_provider', remover_name: 'remove_auth_provider'
    attr_ary_of Authorization::Route, :authorizations, default: [], singleton: true, add_rem: true
    attr_ary_of [String, Regexp], :skip_auth_routes, default: [/^\/(assets\/)?(stylesheets|javascript|fonts)\//i, config.maps_prefix, /^\/__OPAL_SOURCE_MAPS__/i], singleton: true
    attr_ary_of [String, Regexp], :protected_routes, singleton: true

    bridge_method :authorizations, :auth_providers, :auth_sources, :skip_auth_routes, :protected_routes

    config(
      authorization:                true,  # When true authorization rules are run for each request
      authentication:               true,  # When true authentication rules are run for each request
      deny_by_default:              false, # When true, if no authorization rules match a request, the request is denied by default.
      authentication_failure_route: nil,   # The route to redirect to when authentication fails. Setting to nil ignores a redirect and returns a 403.
      authorization_failure_route:  nil,
      homepage:                     '/',   # Sets the url that is considered to be the home page. Mostly used in redirects.
      login_model:                   BlockStack::Authentication::Login # Sets the model that is used when registering new users
    )

    def self.authorize(action, object, allow, opts = {})
      self.authorizations.push(Authorization::Route.new(action, object, { allow: allow }.merge(opts)))
    end

    def authenticate!
      if current_login && current_login.expired?
        logout
        return false
      end
      return true if current_login
      auth_sources.each do |source|
        next if current_login
        creds = source.credentials(request, params)
        next unless creds
        session[:auth_provided] = true
        auth_providers.each do |provider|
          next if current_login
          login = provider.authenticate(*[creds].flatten(1), request: request, params: params)
          next unless login && process_login(login)
          session[:login] = login
        end
      end
      current_login ? true : false
    end

    # Hook that can be overriden to process new logins as they are created.
    # The return should be true/false. When true, the login is considered
    # to be successful and the user is authenticated. If the return is false,
    # the login attempt fails and is then check against any remaining providers.
    def process_login(login)
      login.current_login = Time.now
      login.login_count += 1
      login.save if login.respond_to?(:save)
      true
    rescue BlockStack::InvalidModelError => e
      logger.error(e)
      logger.error(login.errors)
      false
    end

    def authorize!
      return false unless current_login
      return true if authorizations.empty?
      matches = authorizations.find_all do |authorization|
        authorization.match?(request.request_method.downcase, request.path)
      end
      return !config.deny_by_default if matches.empty?
      matches.any? { |auth| auth.permit?(current_login, request, params) }
    end

    def self.skip_auth(*routes)
      routes.map do |route|
        self.skip_auth_routes.push(route) unless skip_auth_routes.include?(route)
      end
    end

    def skip_auth?
      skip_auth_routes.any? do |route|
        case route
        when Regexp
          request.path_info =~ route
        else
          request.path_info == route.to_s
        end
      end
    end

    def self.protect(*routes)
      routes.map do |route|
        self.protected_routes.push(route) unless protected_routes.include?(route)
      end
    end

    def protected?
      protected_routes.any? do |route|
        case route
        when Regexp
          request.path_info =~ route
        else
          request.path_info == route.to_s
        end
      end
    end

    # If the current route matches a protected route protected! is automatically
    # invoked in the before hook below.
    before do
      protected! if protected?
    end

    def current_login
      session[:login]
    end

    alias_method :current_user, :current_login

    def logout
      current_login.last_login = current_login.current_login
      current_login.current_login = nil
      current_login.save
    ensure
      session.clear
    end

    def unauthorized!
      logger.info("Authorization FORBIDDEN for #{current_login.name} for #{request.path_info}")
      return custom_unauthorized! if respond_to?(:custom_unauthorized!)
      if config.authorization_failure_route
        redirect config.authorization_failure_route, 303, notice: 'You are not authorized for that!', severity: :error
      else
        halt 403, 'You are not authorized for that.'
      end
    end

    def unauthenticated!
      if session[:auth_provided]
        logger.info("Authentication failed for request #{request.object_id}.")
      else
        logger.info("Authentication not provided for request #{request.object_id}.")
      end
      return custom_unauthenticated! if respond_to?(:custom_unauthenticated!)
      if config.authentication_failure_route
        redirect to(config.authentication_failure_route), 303, notice: 'Please provide a valid login.', severity: :error
      else
        halt 401, 'Not authorized. Please provide valid credentials.'
      end
    end

    def protected!
      return if skip_auth?
      if authenticate!
        if config.authorization
          if authorize!
            logger.debug("Authorization ALLOWED for #{current_login.name} for #{request.path_info}.")
          else
            unauthorized!
          end
        end
      else
        unauthenticated!
      end
    end

    # TODO Move to "protect_all" template
    # before do
    #   unless skip_auth? || !config.authentication
    #     protected!
    #   end
    # end
  end
end
