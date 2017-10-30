####################
# Features
####################
# *Dynamic Controller Registration
# *API Routes
# *Formatter support
# *Route Removal
# *Route Prefixing
# Route templates (global search, crud, routes)

require_relative 'helpers'

module BlockStack
  class Server < Sinatra::Base
    extend BBLib::Attrs
    extend BBLib::FamilyTree
    extend BBLib::Bridge

    helpers ServerHelpers

    attr_ary_of String, :api_routes, singleton: true, default: [], add_rem: true
    attr_ary_of Formatter, :formatters, default_proc: :default_formatters, singleton: true
    attr_sym :default_format, default: :json, allow_nil: true, singleton: true

    bridge_method :route_map, :route_names, :api_routes, :formatters, :default_formatters, :default_format
    bridge_method :logger, :debug, :info, :warn, :error, :fatal, :request_timer

    # Setup default settings
    # TODO Finalize settings
    set(
      controller_base: nil,  #Set this to a class that inherits from BlockStack::Controller
      log_requests: true,
      log_params: true,
      auto_serialize: true # If true all objects that respond to serialize will be serialized before being passed to the formatter (api routes only)
    )

    class << self
      BlockStack::VERBS.each do |verb|
        define_method(verb) do |route, opts = {}, &block|
          route = build_route(route, verb, api: opts[:api])
          add_api_routes("#{verb.to_s.upcase} #{route}") if opts.delete(:api)
          super(route, opts, &block)
        end

        define_method("#{verb}_api") do |route, opts = {}, &block|
          send(verb, route, opts.merge(api: true), &block)
        end
      end

      [:debug, :info, :warn, :error, :fatal].each do |sev|
        define_method(sev) do |*args|
          args.each { |a| logger.send(sev, a) }
        end
      end
    end

    def self.logger
      @logger ||= BlockStack.logger
    end

    def self.logger=(logr)
      @logger = logr
    end

    def self.prefix
      @prefix
    end

    def self.base_server
      self
    end

    bridge_method :base_server

    def self.prefix=(pre)
      pre = pre.to_s.uncapsulate('/')
      return @prefix if @prefix == pre
      change_prefix(@prefix, pre)
      @prefix = pre
    end

    def self.build_route(path, verb, api: false)
      path = "/#{settings.prefix}#{path}" if settings.prefix
      (path.end_with?('/') ? "#{path}?" : path) + (verb == :get && api ? '(.:format)?' : '')
    end

    def self.route_names(verb)
      return [] unless routes[verb.to_s.upcase]
      routes[verb.to_s.upcase].map { |route| route[0].to_s }
    end

    # Get a list of all registered routes grouped by http verb
    def self.route_map(include_controllers = true)
      BlockStack::VERBS.hmap { |verb| [verb, route_names(verb)] }
    end

    # Convenient way to delete a route from this server
    # TODO (Maybe) Make this also delete controller routes
    def self.remove_route(verb, route)
      index = nil
      verb = verb.to_s.upcase
      routes[verb].each_with_index do |rt, i|
        index = i if rt[0].to_s == route.to_s
      end
      return false unless index
      routes[verb].delete_at(index)
    end

    # Provides a list of controllers that this server should use
    def self.controllers
      ((@controllers ||= []) + load_controller_base).uniq
    end

    # Add a controller to this server
    def self.add_controller(controller)
      raise ArgumentError, "Invalid controller class: #{controller}. Must be inherited from BlockStack::Controller." unless controller <= BlockStack::Controller
      (@controllers ||= [])
      @controllers << controller
    end

    # Remove a controller from this server (does not affect controllers loaded via controller_base)
    def self.remove_controller(controller)
      (@controllers ||= []).delete(controller)
    end

    # Builds a set of default formatters for API routes
    def self.default_formatters
      [
        BlockStack::Formatters::HTML.new,
        BlockStack::Formatters::JSON.new,
        BlockStack::Formatters::YAML.new,
        BlockStack::Formatters::XML.new,
        BlockStack::Formatters::Text.new,
        BlockStack::Formatters::CSV.new,
        BlockStack::Formatters::TSV.new
      ]
    end

    before do
      if settings.log_requests && message = log_request
        info(message)
      end
    end

    # Check each response to see if it is an API route.
    # If it is an API route we will attempt to format the response.
    after do
      if api_routes.include?(request.env['sinatra.route'].to_s)
        formatter = pick_formatter(request, params)
        if formatter
          body = response.body
          if settings.auto_serialize
            if body.respond_to?(:serialize)
              body = body.serialize
            elsif body.is_a?(Array)
              body = body.map { |obj| obj.respond_to?(:serialize) ? obj.serialize : obj }
            end
          end
          content_type(formatter.content_type)
          response.body = formatter.process(body, params)
        else
          halt 406, "No formatter found"
        end
      end

      if settings.log_requests && message = log_request_finished
        info(message)
      end
    end

    def self.request_timer
      @request_timer ||= BBLib::TaskTimer.new
    end

    # This is called in a before block to log requests. Can be overriden in sub classes.
    # To disable request logging either set log_requests to false or make this method return nil.
    def log_request
      request_timer.start(request.object_id)
      "Processing new request (#{request.object_id}) from #{request.host}: #{request.request_method} #{request.path}#{ settings.log_params ? " - #{params}" : nil}"
    end

    def log_request_finished
      "Finished processing request (#{request.object_id}) from #{request.host} (#{request.request_method} #{request.path}). Took #{request_timer.stop(request.object_id).to_duration}."
    end

    # Override default Sinatra run. Registers controllers before running.
    def self.run!(*args)
      logger.info("Starting up your BlockStack server")
      register_controllers
      super
    end

    protected

    # TODO Better support mime type to override default format (Maybe?)
    def pick_formatter(request, params)
      unless params[:format]
        file_type = File.extname(request.path_info).sub('.', '').to_s.downcase.to_sym
        params[:format] = file_type
      end
      formatters.find { |f| f.format_match?(params[:format]) } ||
      default_format && formatters.find { |f| f.format_match?(default_format) } ||
      formatters.find { |f| f.mime_type_match?(request.accept) }
    end

    # Loads all controllers into this server via rack
    def self.register_controllers
      controllers.each do |controller|
        debug("Registering new controller: #{controller}")
        controller.base_server = self
        use controller
      end
    end

    # If a controller base is set, controllers are loaded from it.
    # All descendants of each controller_base will be discovered.
    def self.load_controller_base
      [settings.controller_base].flatten.compact.flat_map(&:descendants).uniq.reject { |c| c == self }
    end

    # This method is invoked any time the prefix of the server is changed.
    # All existing routes will have their route prefix updated.
    def self.change_prefix(old, new)
      if old
        info("Changing prefix from '#{old}' to '#{new}'...")
      else
        info("Adding route prefix to existing routes: #{new}")
      end
      routes.each do |verb, rts|
        rts.each do |route|
          current = route[0].to_s
          full = "#{verb} #{current}"
          if api_routes.include?(full)
            verb, path = api_routes.delete(full).split(' ', 2)
            path = path.sub(/^\/#{Regexp.escape(old)}/i, '') if old
            logger.debug("Changing API route from '#{current}' to /#{new}#{path}")
            add_api_routes("#{verb} /#{new}#{path}")
          end
          current = current.sub(/^\/#{Regexp.escape(old)}/i, '') if old
          route[0] = Mustermann.new("/#{new}#{current}", route[0].options)
        end
      end
    end
  end
end
