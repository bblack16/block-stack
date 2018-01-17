module BlockStack
  class Controller < BlockStack::Server
    attr_ary_of MenuItem, :sub_menus, default: [], singleton: true, add_rem: true, adder: 'add_sub_menu', remover: 'remove_sub_menu'

    set(
      default_view_folder: 'default' # Sets the default folder to load fallback views from.
    )

    def self.menu
      base_server.menu
    end

    def self.crud(opts = {})
      self.model = opts[:model] if opts[:model]
      raise RuntimeError, "No model was found for controller #{self}." unless self.model
      self.prefix = opts.include?(:prefix) ? opts[:prefix] : model.plural_name

      add_sub_menus(
        {
          title: model.clean_name.pluralize,
          path: opts[:menu_path] || [],
          icon: config.icon,
          items: [
            { title: 'Browse', icon: '<i class="fa fas-list"/>', attributes: { href: "/#{prefix}/" } },
            { title: "New #{model.clean_name}", icon: '<i class="fa fas-plus"/>', attributes: { href: "/#{prefix}/new" } }
          ]
        }
      )

      attach_template_group(:crud, *(opts[:ignore] || []))
      true
    end

  end
end
