require 'opal'
require 'opal-jquery'
require 'opal-browser'
# require 'reactrb'

require_relative 'util/helpers'

module BlockStack
  class UiServer < Server

    enable :sessions
    set global_search: false, precompile: false

    helpers UiHelpers

    IMAGE_TYPES = [:svg, :png, :jpg, :jpeg, :gif].freeze

    Opal.use_gem 'bblib'
    Opal.use_gem 'dformed'

    def self.assets
      @assets ||= default_assets
    end

    def self.assets=(assets)
      @assets = assets
    end

    def self.default_assets
      {
        assets: [File.expand_path("../app", __FILE__)],
        views: [File.expand_path("../app/views", __FILE__)]
      }
    end

    def self.assets_prefix
      @assets_prefix ||= '/assets'
    end

    def self.maps_prefix
      @maps_prefix ||= '/__OPAL_SOURCE_MAPS__'
    end

    def self.maps_app
      @maps_app ||= Opal::SourceMapServer.new(sprockets, maps_prefix)
    end

    def self.opal
      exists = @opal
      @opal ||= Opal::Server.new do |s|
        s.append_path "#{File.expand_path('../app', __FILE__)}"
        s.main = 'javascript/application'
      end
      setup_sprockets unless exists
      @opal
    end

    def self.setup_sprockets
      sprocket_paths.each do |path|
        opal.append_path(path) if @opal && !@opal.sprockets.paths.include?(path)
      end
    end

    def self.sprocket_paths
      assets[:assets]
    end

    ASSET_TYPES = [:views, :assets, :models]

    def self.asset_path(type, *paths)
      return unless ASSET_TYPES.include?(type)
      assets[type] = (paths.flatten + (assets[type] || [])).uniq
    end

    class << self
      ASSET_TYPES.each do |type|
        define_method("#{type}_path") do |*paths|
          asset_path(type, *paths)
        end
      end

      def crud(model, opts = {})
        name        = model.model_name
        plural      = model.plural_name
        ivar        = "@#{name}"
        ivar_plural = "@#{plural}"
        prefix      = "#{opts[:prefix] || plural}"
        engine      = opts[:engine] || :slim

        get '/' do
          session[:display] = params[:display] if params[:display]
          begin
            limit = params[:limit]&.to_i || 25
            offset = ((params[:page]&.to_i || 1) - 1) * limit
            instance_variable_set(ivar_plural, model.all(limit: limit, offset: offset))
            send(engine, :"#{prefix}/index")
          rescue Errno::ENOENT => e
            @models     = instance_variable_get(ivar_plural)
            @model      = model
            slim :'defaults/index'
          end
        end

        get '/new' do
          begin
            @model = model.new(opts[:defaults] || {})
            instance_variable_set(ivar, @model)
            send(engine, :"#{prefix}/new")
          rescue Errno::ENOENT => e
            slim :'defaults/new'
          end
        end

        get '/:id' do
          begin
            @model = model.find(params[:id])
            if @model
              instance_variable_set(ivar, @model)
              send(engine, :"#{prefix}/show")
            else
              redirect "/#{route_prefix}", notice: "Could not locate any #{model.clean_name.pluralize} with an id of #{params[:id]}."
            end
          rescue Errno::ENOENT => e
            slim :'defaults/show'
          end
        end

        get '/:id/edit' do
          begin
            @model = model.find(params[:id])
            if @model
              instance_variable_set(ivar, @model)
              send(engine, :"#{prefix}/edit")
            else
              redirect "/#{route_prefix}", notice: "Could not locate any #{model.clean_name.pluralize} with an id of #{params[:id]}."
            end
          rescue Errno::ENOENT => e
            slim :'defaults/edit'
          end
        end

        super
      end

      def add_global_search
        set global_search: true

        get '/search' do
          @results = nil
          if params[:query]
            @results = BlockStack::Model.included_classes_and_descendants.flat_map do |model|
              next unless model.setting(:global_search)
              model.search(params[:query])
            end.compact.uniq
          end
          slim :'defaults/global_search'
        end
      end
    end

    def self.precompile!
      BlockStack.logger.info("BlockStack: Compiling assets in #{settings.public_folder}...")
      environment = opal.sprockets
      manifest = Sprockets::Manifest.new(environment.index, settings.public_folder)
      manifest.compile([/stylesheets\/[\w\d\s]+\.css/] + %w(application.rb javascript/*.js *.png *.jpg *.svg *.eot *.ttf *.woff *.woff2))
    end

    def self.run!(*args)
      precompile! if settings.precompile
      super
    end

    def self.menu
      {
        title: title,
        main_menu: main_menu
      }
    end

    def self.title
      settings.app_name || base_server.to_s.split('::').last
    rescue => e
      base_server.to_s.split('::').last
    end

    def self.main_menu
      @main_menu ||= construct_menu
    end

    def self.construct_menu
      menu = {
        home: {
          text: 'Home',
          href: '/',
          fa_icon: 'home',
          title: 'Head to the home page',
          tooltip: 'true',
          'data-placement': 'bottom',
          'data-animation': 'true',
          'data-replace': "true",
          class: 'pmd-tooltip',
          active_when: [
            '/'
          ]
        }
      }
      controllers.sort_by(&:to_s).map do |c|
        begin
          menu = menu.merge(c.main_menu)
        rescue => e
          puts e
          nil
        end
      end
      menu
    end

    def self.load_assets
      assets[:assets].each do |path|
        BBLib.scan_files(path, /#{Regexp.escape(path)}\/models\/.*\.rb$/i, recursive: true) do |file|
          begin
            puts "Loaded #{file}"
            require file
          rescue => e
            puts "Failed to load #{file}: #{e}"
          end
        end
      end
    end

    helpers do
      def find_template(views, name, engine, &block)
        ((views.is_a?(Array) ? views : []) + self.class.assets[:views]).uniq.each { |view| super(view, name, engine, &block) }
      end
    end

    get maps_prefix do
      maps_app.call(maps_prefix)
    end

    get '/assets/*' do
      env['PATH_INFO'].sub!('/assets', '')
      self.class.opal.sprockets.call(env)
    end

    get '/fonts/*' do
      redirect request.path_info.sub('fonts', 'assets/fonts')
    end

    # get '/' do
    #   slim :index
    # end
    #
    # get '/examples' do
    #   slim :examples
    # end
  end
end
