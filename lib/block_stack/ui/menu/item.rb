module BlockStack
  class MenuItem < Menu

    attr_str :title, required: true, arg_at: 0, pre_proc: :parse_path
    attr_ary_of [String], :path
    attr_hash :attributes, default: {}
    attr_int :sort, default: 1
    attr_ary_of [String, Regexp], :active_expressions, default: []
    attr_bool :match_href, default: true
    attr_of [String, Symbol, BBLib::HTML::Tag], :icon, default: nil, allow_nil: true
    attr_ary_of MenuItem, :items

    init_type :loose

    after :items=, :add_items, :sort_items

    # Stubbed in for authentication support. By default this always returns true
    def authorized?(user, request, params)
      true
    end

    def sort_items
      @items = items.sort_by { |i| [i.sort, i.title] }
    end

    def clean_title
      title.gsub(/\s+/, '_').downcase.to_clean_sym
    end

    def merge!(item)
      item.serialize.only(:sort, :match_href, :icon).each do |k, v|
        send("#{k}=", v)
      end
      self.items = (self.items + item.items).uniq
      self.active_expressions = (self.active_expressions + item.active_expressions).uniq
      self.attributes.merge!(item.attributes)
    end

    # Returns true if there are any items (aka sub menus)
    def sub_menu?
      items && (items.empty? ? false : true)
    end

    # This can be called with a route to determine if this menu item should be
    # considered the active location on the navbar.
    def active?(route)
      match_href? && attributes[:href] == route ||
      active_expressions.any? do |exp|
        if exp.is_a?(Regexp)
          route =~ exp
        else
          route == exp
        end
      end
    end

    def items=(items)
      @items = []
      [items].flatten.each { |item| add_item(item) }
    end

    def add_items(*items)
      items.each { |item| add_item(item) }
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

    protected

    def simple_init(*args)
      BBLib.named_args(*args).each do |k, v|
        next if _attrs.include?(k)
        self.attributes[k] = v
      end
    end

    def parse_path(str)
      if str.is_a?(Array)
        self.path = str[0..-2]
        str.last
      else
        path = str.to_s.uncapsulate('/').split(/(?=[^\\])\//)
        self.path = path[0..-2] if path.size != 1
        path.last
      end
    end
  end
end
