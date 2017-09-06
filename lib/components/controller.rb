
module BlockStack
  class Controller < BlockStack::UiServer

    def self.sub_menus
      @sub_menus ||= {}
    end

    def self.add_sub_menu(name, opts = {})
      sub_menus[name] = opts
    end

    def self.model
      @model ||= BlockStack::Model.model_for(model_name)
    end

    def model
      self.class.model
    end

    def self.model=(klass)
      @model = klass
    end

    def self.model_name
      self.to_s.split('::').last.sub(/controller$/i, '').method_case.to_sym
    end

    def self.crud(custom_model = nil, opts = {})
      custom_model = model unless custom_model
      add_sub_menu(:index, text: 'All', href: "/#{route_prefix}")
      add_sub_menu(:new, text: 'New', href: "/#{route_prefix}/new")
      super(custom_model, opts)
    end

    def self.route_prefix
      self.to_s.split('::').last.sub(/Controller$/, '').method_case.pluralize
    end

    def self.api_route_prefix
      "api/#{route_prefix}"
    end

    def self.base_server(server = nil)
      @base_server = server if server
      @base_server
    end

    def self.menu
      base_server.menu
    end

    def self.main_menu
      {
        model.dataset_name => {
          text: model.clean_name.pluralize,
          href: "/#{model.dataset_name}",
          icon: model.setting(:icon) || "#{model.dataset_name}/icon",
          fa_icon: model.setting(:fa_icon),
          active_when: [/\/#{Regexp.escape(model.dataset_name)}/],
          sub: sub_menus
        }
      }
    end
  end
end

BlockStack::UiServer.set(controller_base: BlockStack::Controller)
BlockStack::Controller.set(controller_base: nil)
