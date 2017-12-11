module BlockStack
  class Controller < BlockStack::Server

    attr_bool :controller_auth, default: false

    def authorizations
      self.class.authorizations + (base_server ? base_server.authorizations : [])
    end

    def auth_providers
      self.class.auth_providers + (base_server ? base_server.auth_providers : [])
    end

    def auth_sources
      self.class.auth_sources + (base_server ? base_server.auth_sources : [])
    end

    def skip_auth_routes
      self.class.skip_auth_routes + (base_server ? base_server.skip_auth_routes : [])
    end

    def self.authentication_failure_route
      base_server.authentication_failure_route
    end

    def self.authorization_failure_route
      base_server.authorization_failure_route
    end

    def self.authorization
      base_server.authorization
    end

    def self.authentication
      base_server.authentication
    end

    def self.user_model
      base_server.user_model
    end

    def authenticate!
      # return base_server.authenticate! unless controller_auth
    end

    def authorize!
      # return base_server.authorize! unless controller_auth
    end

    def skip_auth_routes
      self.class.skip_auth_routes + base_server.skip_auth_routes
    end

    def unauthorized!
      # return base_server.unauthorized! unless controller_auth
    end

    def unauthenticated!
      # return base_server.unauthenticated! unless controller_auth
    end

    def protected!
      # return base_server.protected! unless controller_auth
    end

  end
end
