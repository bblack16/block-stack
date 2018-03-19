module BlockStack
  module Authorization
    class Match
      include BBLib::Effortless
      TYPES = [:role, :username, :ip, :param, :attribute].freeze
      MATCH_TYPES = [:any, :all]

      attr_element_of TYPES, :type, default: TYPES.first, arg_at: 0
      attr_ary_of Object, :expressions, default: [], arg_at: 1
      attr_sym :param, :attribute, default: nil, allow_nil: true
      attr_of Proc, :custom_compare, default: nil, allow_nil: true
      attr_element_of MATCH_TYPES, :match_type, default: MATCH_TYPES.first

      def match?(user, request, params)
        values = get_value(user, request, params)
        return false unless values
        [values].flatten.any? do |value|
          expressions.send("#{match_type}?") do |exp|
            compare(value, exp)
          end
        end
      end

      protected

      def get_value(user, request, params)
        case type
        when :role
          user.roles.map(&:name)
        when :username
          user.name
        when :ip
          request.remote_address
        when :param
          params[self.param]
        when :attribute
          user.send(attribute) rescue nil
        else
          nil
        end
      end

      def compare(a, b)
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
