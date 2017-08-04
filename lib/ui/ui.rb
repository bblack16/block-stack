require 'opal'
require 'opal-jquery'
require 'opal-browser'
require 'reactrb'

require_relative 'helpers'

module BlockStack
  class UiServer < Server

    helpers UiHelpers

    IMAGE_TYPES = [:svg, :png, :jpg, :jpeg, :gif].freeze

    Opal.use_gem 'bblib'
    Opal.use_gem 'dformed'

    before do
      request[:menu] = build_menu
    end

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

    def self.prefix
      @prefix ||= '/assets'
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
    end

    def self.precompile!
      p "BlockStack: Compiling assets in #{settings.public_folder}..."
      # FileUtils.rm_rf(settings.public_folder)
      environment = opal.sprockets
      manifest = Sprockets::Manifest.new(environment.index, settings.public_folder)
      manifest.compile(%w(*.css application.rb javascript/*.js *.png *.jpg *.svg *.eot *.ttf *.woff *.woff2))
    end


    def self.menu(env)
      {
        title: title(env),
        main_menu: main_menu(env)
      }
    end

    def self.title(env)
      to_s.split('::').last
    end

    def self.main_menu(env)
      {
        home: {
          text: 'Home',
          href: '/',
          title: 'Head to the home page',
          tooltip: 'true',
          'data-placement': 'bottom',
          'data-animation': 'true',
          'data-replace': "true",
          class: 'pmd-tooltip',
          active_when: [
            '/'
          ]
        },
        sub_menu: {
          text: 'Dropdown Menu',
          'data-placement': 'bottom',
          'data-animation': 'true',
          'data-replace': "true",
          active_when: [
            '/never__'
          ],
          sub: {
            option1: {},
            option2: {},
            option3: {}
          }
        },
        examples: {
          text: 'Examples',
          href: '/examples',
          'data-placement': 'bottom',
          'data-animation': 'true',
          'data-replace': "true",
          active_when: [
            '/examples'
          ]
        },
        gems: {
          text: '',
          href: '/gems',
          title: 'View the currently loaded gems on the server.',
          tooltip: 'true',
          style: 'float: right',
          class: 'fa fa-diamond transition-all-2 gem',
          'data-placement': 'bottom',
          'data-animation': 'true',
          'data-push': "true",
          active_when: [
            '/gems'
          ]
        }
      }
    end

    def self.load_assets
      assets[:assets].each do |path|
        BBLib.scan_files(path, /#{Regexp.escape(path)}\/?(controllers|models)\/.*\.rb$/i, recursive: true) do |file|
          begin
            puts "Loaded #{file}"
            require file
          rescue => e
            puts "Failed to load #{file}: #{e}"
          end
        end
        Controller.descendants.each do |cont|
          cont.assets = assets
          use cont
        end
      end
    end

    def self.run!(*args)
      super
      load_assets
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

    get '/' do
      slim :index
    end

    get '/examples' do
      slim :examples
    end

  end
end
