module BlockStack
  class Server
    enable :sessions

    attr_ary_of Authentication::Source, :auth_sources, default: [], singleton: true, add_rem: true
    attr_ary_of Authentication::Provider, :auth_providers, default: [], singleton: true, add_rem: true
    attr_ary_of Authorization::Route, :authorizations, default: [], singleton: true, add_rem: true
    attr_ary_of [String, Regexp], :skip_auth_routes, default: [/^\/(assets\/)?(stylesheets|javascript|fonts)\//i, maps_prefix, /^\/__OPAL_SOURCE_MAPS__/i], singleton: true

    bridge_method :authorizations, :auth_providers, :auth_sources, :skip_auth_routes

    set(
      authorization:                true,  # When true authorization rules are run for each request
      authentication:               true,  # When true authentication rules are run for each request
      deny_by_default:              false, # When true, if noth authorization rules match a request, the request is denied by default.
      authentication_failure_route: nil,   # The route to redirect to when authentication fails. Setting to nil ignores a redirect and returns a 403.
      authorization_failure_route:  nil,
      homepage:                     '/',   # Sets the url that is considered to be the home page. Mostly used in redirects.
      user_model:                   BlockStack::User # Sets the model that is used when registering new users
    )

    def self.authorize(action, object, allow, opts = {})
      self.authorizations.push(Authorization::Route.new(action, object, { allow: allow }.merge(opts)))
    end

    def authenticate!
      if current_user && current_user.expired?
        logout
        return false
      end
      return true if current_user
      auth_sources.each do |source|
        next if current_user
        creds = source.credentials(request, params)
        next unless creds
        auth_providers.each do |provider|
          next if current_user
          user = provider.authenticate(*(creds + [request, params]))
          next unless user
          begin
            user.current_login = Time.now
            user.login_count += 1
            user.save
          rescue BlockStack::Model::InvalidModel => e
            logger.error(e)
            logger.error(user.errors)
          end
          session[:user] = user
        end
      end
      current_user ? true : false
    end

    def authorize!
      return false unless current_user
      return true if authorizations.empty?
      matches = authorizations.find_all do |authorization|
        authorization.match?(request.request_method.downcase, request.path)
      end
      return !settings.deny_by_default if matches.empty?
      matches.any? { |auth| auth.permit?(current_user, request, params) }
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

    def current_user
      session[:user]
    end

    def logout
      current_user.last_login = current_user.current_login
      current_user.current_login = nil
      current_user.save
    ensure
      session.clear
    end

    def unauthorized!
      logger.info("Authorization FORBIDDEN for #{current_user.name} for #{request.path_info}")
      return custom_unauthorized! if respond_to?(:custom_unauthorized!)
      if settings.authorization_failure_route
        redirect settings.authorization_failure_route, 303, notice: 'You are not authorized for that!', severity: :error
      else
        halt 403, 'You are not authorized for that.'
      end
    end

    # TODO Enhance logging to log whether auth was not provided or was but failed
    def unauthenticated!
      logger.info("Authentication not provided or failed for request #{request.object_id}.")
      p "ORIGINAL UNAUTH: #{self.respond_to?(:custom_unauthenticated!)}"
      p self
      return custom_unauthenticated! if respond_to?(:custom_unauthenticated!)
      if settings.authentication_failure_route
        redirect to(settings.authentication_failure_route), 303, notice: 'Please provide a valid login.', severity: :error
      else
        halt 403, 'Not authorized. Please provide valid credentials.'
      end
    end

    def protected!
      if authenticate!
        if settings.authorization
          if authorize!
            logger.debug("Authorization ALLOWED for #{current_user.name} for #{request.path_info}.")
          else
            unauthorized!
          end
        end
      else
        unauthenticated!
      end
    end

    # TODO Move to "protect_all" template
    before do
      unless skip_auth? || !settings.authentication
        protected!
      end
    end
  end
end
