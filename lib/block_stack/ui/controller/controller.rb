module BlockStack
  class Controller < BlockStack::Server
    attr_ary_of Menu::Item, :sub_menus, default: [], singleton: true, add_rem: true, adder: 'add_sub_menu', remover: 'remove_sub_menu'

  end
end
