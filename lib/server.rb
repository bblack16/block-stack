####################
# Features
####################
# Dynamic Controller Registration
# API Routes
# Formatter support
# Route Removal
# Route templates (global search, crud, routes)


module BlockStack
  class Server < Sinatra::Base
    extend BBLib::Attrs
    extend BBLib::FamilyTree
    extend BBLib::Bridge

    bridge_method :route_map, :route_names

    # Set default settings
    set(
      controller_base: nil,  #This gets set in block_stack.rb
      prefix:          nil,  # All routes will be prefixed with this
      api_prefix:      nil   # Sets an additional prefix for api routes
    )

    def self.route_names(verb)
      return [] unless routes[verb.to_s.upcase]
      routes[verb.to_s.upcase].map { |route| route[0].to_s }
    end

    # Get a list of all registered routes grouped by http verb
    def self.route_map(include_controllers = true)
      BlockStack::VERBS.hmap { |verb| [verb, route_names(verb)] }
    end

    # Convenient way to delete a route from this server
    # TODO Make this also delete controller routes
    def self.remove_route(verb, route)
      # TODO
    end

    # Provides a list of controllers that this server should use
    def self.controllers
      ((@controllers ||= []) + load_controller_base).uniq
    end

    # Add a controller to this server
    def self.add_controller(controller)
      raise ArgumentError, "Invalid controller class: #{controller.class}. Must be inherited from #{self.class}." unless controller.is_a?(Controller)
      (@controllers ||= [])
      @controllers << controller
    end

    # Remove a controller from this server (does not affect controllers loaded via controller_base)
    def self.remove_controller(controller)
      (@controllers ||= []).delete(controller)
    end

    # Override default Sinatra run. Registers controllers before running.
    def run!(*args)
      register_controllers
      super
    end

    protected

    # Loads all controllers into this server via rack
    def self.register_controllers
      controllers.each do |controller|
        controller.base_server = self
        use controller
      end
    end

    # If a controller base is set, controllers are loaded from it.
    # All descendants of each controller_base will be discovered.
    def self.load_controller_base
      [settings.controller_base].flatten.compact.flat_map(&:descendants).uniq.reject { |c| c == self }
    end
  end
end
