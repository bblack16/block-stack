module BlockStack
  class Controller < BlockStack::Server
    attr_ary_of Menu::Item, :sub_menus, default: [], singleton: true, add_rem: true, adder: 'add_sub_menu', remover: 'remove_sub_menu'

    set(
      default_view_folder: 'default' # Sets the default folder to load fallback views from.
    )

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
          slim :"#{settings.default_view_folder}/index"
        end
      end

      get '/new' do
        begin
          @model = model.new(opts[:new_defaults] || {})
          send(engine, :"#{model.plural_name}/new")
        rescue Errno::ENOENT => e
          slim :"#{settings.default_view_folder}/new"
        end
      end

      get '/:id' do
        begin
          @model = model.find(params[:id])
          if @model
            send(engine, :"#{model.plural_name}/show")
          else
            redirect "/#{model.plural_name}", notice: "Could not locate any #{model.clean_name.pluralize} with an id of #{params[:id]}."
          end
        rescue Errno::ENOENT => e
          slim :"#{settings.default_view_folder}/show"
        end
      end

      get '/:id/edit' do
        begin
          @model = model.find(params[:id])
          if @model
            send(engine, :"#{model.plural_name}/edit")
          else
            redirect "/#{model.plural_name}", notice: "Could not locate any #{model.clean_name.pluralize} with an id of #{params[:id]}."
          end
        rescue Errno::ENOENT => e
          slim :"#{settings.default_view_folder}/edit"
        end
      end
    end

  end
end
