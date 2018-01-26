


module BlockStack
  class Menu
    include BBLib::Effortless
    require_relative 'item'

    attr_str :title, default: :menu
    attr_ary_of MenuItem, :items, default: []

    after :items=, :add_items, :sort_items

    def sort_items
      @items = items.sort_by { |i| [i.sort, i.title] }
    end

    def items=(items)
      @items = []
      [items].flatten.each { |item| add_item(item) }
    end

    def item(title)
      path = Menu.parse_path(title)
      match = items.find { |item| item.title == path.first }
      return nil unless match
      return match.item(path[1..-1]) if path.size > 1
      match
    end

    def item?(title)
      items.any? { |item| item.title == title }
    end

    def add_items(*items)
      items.each { |item| add_item(item) }
    end

    def add_item(item)
      item = MenuItem.new(item) if item.is_a?(Hash) || item.is_a?(String)
      if item.path.empty?
        if match = items.find { |i| i.title == item.title }
          match.merge!(item)
        else
          self.items.push(item)
        end
      else
        if parent = items.find { |i| i.title == item.path.first }
          item.path.shift
          parent.add_item(item)
        else
          parent = MenuItem.new(item.path.shift)
          self.items.push(parent)
          parent.add_item(item)
        end
      end
    end

    def self.parse_path(str)
      if str.is_a?(Array)
        str
      else
        str.to_s.uncapsulate('/').split(/(?=[^\\])\//)
      end
    end
  end
end
