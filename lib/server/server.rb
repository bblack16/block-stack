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

    attr_ary_of String, :api_routes, singleton: true, default_proc: :inherited_api_routes, add_rem: true
    attr_ary_of Formatter, :formatters, default_proc: :default_formatters, singleton: true
    attr_sym :default_format, default: :json, allow_nil: true, singleton: true

    bridge_method :route_map, :route_names, :api_routes, :formatters, :default_formatters, :default_format

    # Setup default settings
    # TODO Finalize settings
    set(
      controller_base: nil  #Set this to a class that inherits from BlockStack::Controller
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
    end

    def self.prefix
      @prefix
    end

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

    after do
      if api_routes.include?(request.env['sinatra.route'].to_s)
        formatter = pick_formatter(request, params)
        if formatter
          content_type(formatter.content_type)
          response.body = formatter.process(response.body, params)
        else
          halt 406, "No formatter found"
        end
      end
    end

    # Override default Sinatra run. Registers controllers before running.
    def run!(*args)
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
        controller.base_server = self
        use controller
      end
    end

    # If a controller base is set, controllers are loaded from it.
    # All descendants of each controller_base will be discovered.
    def self.load_controller_base
      [settings.controller_base].flatten.compact.flat_map(&:descendants).uniq.reject { |c| c == self }
    end

    def self.change_prefix(old, new)
      routes.each do |verb, rts|
        rts.each do |route|
          current = route[0].to_s
          current = current.sub(/^\/#{Regexp.escape(old)}/i, '') if old
          route[0] = Mustermann.new("/#{new}#{current}", route[0].options)
        end
      end
    end

    def self.inherited_api_routes
      ancestors.flat_map do |ancestor|
        next if ancestor == self
        if ancestor.respond_to?(:api_routes)
          ancestor.api_routes
        end
      end.compact.uniq
    end
  end
end
