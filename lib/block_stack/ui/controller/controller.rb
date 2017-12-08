module BlockStack
  class Controller < BlockStack::Server
    attr_ary_of Menu::Item, :sub_menus, default: [], singleton: true, add_rem: true, adder: 'add_sub_menu', remover: 'remove_sub_menu'

    set(
      default_view_folder: 'default' # Sets the default folder to load fallback views from.
    )

    def self.menu
      base_server.menu
    end

    def self.crud(opts = {})
      self.model = opts[:model] if opts[:model]
      self.prefix = opts.include?(:prefix) ? opts[:prefix] : model.plural_name

      add_sub_menus(
        {
          title: model.clean_name.pluralize,
          fa_icon: respond_to?(:fa_icon) ? fa_icon : nil ,
          items: [
            { title: 'Browse', fa_icon: 'list', attributes: { href: "/#{prefix}/" } },
            { title: "New #{model.clean_name}", fa_icon: 'plus', attributes: { href: "/#{prefix}/new" } }
          ]
        }
      )

      attach_route_template_group(:crud, *(opts[:ignore] || []))
      true
    end

  end
end
