module BlockStack
  class Menu
    class Item
      include BBLib::Effortless

      attr_str :title, required: true

      attr_hash :attributes, default: {}
      attr_int :sort, default: 1
      attr_ary_of [String, Regexp], :active_expressions, default: []
      attr_bool :match_href, default: true
      attr_str :icon, :fa_icon, default: nil, allow_nil: true
      attr_ary_of Item, :items, add_rem: true, default: nil, allow_nil: true

      def clean_title
        title.gsub(/\s+/, '_').downcase.to_clean_sym
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
    end
  end
end
