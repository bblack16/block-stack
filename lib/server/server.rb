module BlockStack
  class Server < Sinatra::Base
    extend BBLib::Attrs

    use Rack::Deflater

    class << self
      BlockStack::VERBS.each do |verb|
        define_method(verb) do |path, opts = {}, &block|
          super(build_route(path), opts, &block)
        end

        define_method("#{verb}_api") do |route, version: nil, prefix: nil, &block|
          path = [prefix, (version ? "v#{version}" : nil), route].compact.join('/')
          path = "#{build_route(path)}#{verb == :get ? '(.:format)?' : nil}".pathify
          self.api_routes.push("#{verb.to_s.upcase} #{path}")
          send(verb, path, &block)
        end
      end
    end

    def self.build_route(path)
      if route_prefix
        '/' + route_prefix.to_s + path.to_s
      else
        path
      end
    end

    def self.route_prefix
      settings.prefix
    rescue => e
      nil
    end

    def self.default_formatter(key = nil)
      if key
        @default_formatter = key
      else
        @default_formatter ||= :json
      end
    end

    def default_formatter
      self.class.default_formatter
    end

    def self.default_formatters
      {
        json:  { formatter: BlockStack::Formatters::JSON, content_type: :json },
        yaml:  { formatter: BlockStack::Formatters::YAML, content_type: :yaml },
        xml:   { formatter: BlockStack::Formatters::XML, content_type: :xml },
        txt:   { formatter: BlockStack::Formatters::Text, content_type: :text },
        csv:   { formatter: BlockStack::Formatters::CSV, content_type: :csv },
        tsv:   { formatter: BlockStack::Formatters::CSV, content_type: :tsv },
        table: { formatter: BlockStack::Formatters::Table.new, content_type: :html }
      }
    end

    def self.formatters
      @formatters ||= default_formatters
    end

    def formatters
      self.class.formatters
    end

    def self.add_format(format, content_type, formatter = nil, &block)
      raise ArgumentError, 'You must pass either a proc or an object that responds to :process and takes two arguments.' unless formatter.respond_to?(:process) || formatter.is_a?(Proc) || (formatter.nil? && block_passed?)
      formatters[format] = { formatter: (formatter || block), content_type: content_type }
    end

    def self.api_routes
      @api_routes ||= inherited_api_routes
    end

    def self.inherited_api_routes
      ancestors.flat_map do |ancestor|
        next if ancestor == self
        if ancestor.respond_to?(:api_routes)
          ancestor.api_routes
        end
      end.compact.uniq
    end

    def api_routes
      self.class.api_routes
    end

    after do
      if api_routes.include?(request.env['sinatra.route']) || request[:api_mode]
        format = (params[:format] || File.extname(request.path_info).sub('.', '')).to_s.downcase.to_sym
        if formatter = formatters[format] || formatters[default_formatter]
          formatter[:formatter].respond_to?(:process) ? formatter[:formatter].process(response, request, params) : formatter[:formatter].call(response, request, params)
          content_type formatter[:content_type]
        else
          content_type :json
          { error: "Unsupported format: #{format}" }.to_json
        end
      end
    end

    def self.clone(name)
      name = name.to_s.capitalize unless name.to_s.capital?
      Object.const_set(name, Class.new(self))
    end


    def self.route_names(verb)
      return [] unless routes[verb.to_s.upcase]
      routes[verb.to_s.upcase].map { |r| r[0].to_s }
    end

    def self.descendants(include_singletons = false)
      ObjectSpace.each_object(Class).select do |c|
        (include_singletons || !c.singleton_class?) && c < self
      end
    end
  end
end
