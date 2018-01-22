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
      opts[:model] = Model.model_for(opts[:model]) if opts[:model].is_a?(Symbol)
      self.model = opts[:model] if opts[:model]
      raise RuntimeError, "No model was found for controller #{self}." unless self.model
      self.prefix = opts.include?(:prefix) ? opts[:prefix] : model.plural_name

      unless opts[:no_menu] || opts[:menu]
        add_sub_menus(
          {
            title: "#{([opts[:menu_path]] || []).flatten.join('/')}/#{model.config.display_name.pluralize}",
            icon: opts[:icon] || config.icon,
            href: "/#{prefix}/"
          }.merge(opts[:menu_args] || {})
        )
      end

      add_sub_menus(opts[:menu]) if opts[:menu]

      attach_template_group(:crud, *(opts[:ignore] || []))
      true
    end

  end
end
