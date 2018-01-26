module BlockStack
  module Authorization
    class Route < Base
      attr_elements_of BlockStack::VERBS, :actions, default: [], arg_at: 0
      attr_ary_of Object, :objects, arg_at: 1

      def match?(action, object)
        objects.any? { |obj| compare(object, obj) } && actions.any? { |act| compare(action, act) }
      end

      protected

      def compare(a, b)
        b = /^#{Regexp.escape(b).gsub('\\*', '.*').gsub('\\?', '?')}$/i if b.is_a?(String) && (b.include?('*') || b.include?('?'))
        case b
        when Regexp
          a.to_s =~ b
        when Proc
          [b.call].flatten.compact.any? { |v| compare(a, v) }
        else
          a.to_s == b.to_s
        end
      end

    end
  end
end
