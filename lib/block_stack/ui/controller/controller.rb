module BlockStack
  class Controller < BlockStack::Server
    attr_ary_of Menu::Item, :sub_menus, default: [], singleton: true, add_rem: true, adder: 'add_sub_menu', remover: 'remove_sub_menu'

    class << self
      alias crud_api crud
    end

    def self.menu
      base_server.menu
    end

    def self.crud(opts = {})
      crud_api(opts)
      engine = opts[:engine] || settings.default_renderer
      add_sub_menus(
        {
          title: model.clean_name.pluralize,
          items: [
            { title: 'Browse', fa_icon: 'eye', attributes: { href: "/#{prefix}/" } },
            { title: 'New Game', fa_icon: 'plus', attributes: { href: "/#{prefix}/new" } }
          ]
        }
      )

      get '/' do
        begin
          @models = model.all
          send(engine, :"#{model.plural_name}/index")
        rescue Errno::ENOENT => e
          @model = model
          @models = model.all
          slim :'default/index'
        end
      end

      get '/new' do
        begin
          @model = model.new(opts[:new_defaults] || {})
          send(engine, :"#{model.plural_name}/new")
        rescue Errno::ENOENT => e
          slim :'default/new'
        end
      end
    end

  end
end
