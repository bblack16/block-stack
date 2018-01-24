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

    def protected_routes
      self.class.protected_routes + (base_server ? base_server.protected_routes : [])
    end

    def self.authentication_failure_route
      base_server.config.authentication_failure_route
    end

    def self.authorization_failure_route
      base_server.config.authorization_failure_route
    end

    def self.authorization
      base_server.config.authorization
    end

    def self.authentication
      base_server.config.authentication
    end

    def self.user_model
      base_server.config.login_model
    end
  end
end
