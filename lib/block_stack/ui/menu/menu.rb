
require_relative 'item'

module BlockStack
  class Menu
    include BBLib::Effortless

    attr_str :title, required: true
    attr_ary_of Item, :items, add_rem: true, default: []

    after :items=, :add_items, :sort_items

    def sort_items
      @items = items.sort_by { |i| i.sort }
    end
  end
end
