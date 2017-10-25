

module BlockStack
  class UiController < BlockStack::UiServer
    include ControllerUtil

    def self.crud(custom_model = nil, opts = {})
      custom_model = model unless custom_model
      add_sub_menu(:index, text: "Browse #{custom_model.clean_name.pluralize}", href: "/#{route_prefix}", fa_icon: :list)
      add_sub_menu(:new, text: "New #{custom_model.clean_name}", href: "/#{route_prefix}/new", fa_icon: :plus)
      super(custom_model, opts)
    end

    def self.sub_menus
      @sub_menus ||= {}
    end

    def self.add_sub_menu(name, opts = {})
      sub_menus[name] = opts
    end

    def self.menu
      base_server.menu
    end

    def self.main_menu
      {
        model.dataset_name => {
          text: model.clean_name.pluralize,
          href: "/#{model.dataset_name}",
          # icon: model.setting(:icon),
          fa_icon: model.setting(:fa_icon),
          active_when: [/\/#{Regexp.escape(model.dataset_name)}/],
          sub: sub_menus
        }.select { |k, v| v }
      }
    end
  end
end

BlockStack::UiServer.set(controller_base: BlockStack::UiController)
BlockStack::UiController.set(controller_base: nil)
