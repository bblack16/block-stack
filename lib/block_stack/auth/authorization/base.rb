module BlockStack
  module Authorization
    class Base
      include BBLib::Effortless
      attr_ary_of Match, :allow, :deny, default: []
      attr_bool :prefer_allow, default: true
      attr_bool :allow_all, :deny_all, default: false
      attr_bool :allow_by_default, :deny_by_default, default: false

      # This method should be overwritten in subclasses
      # match? returns true if this auth object applies to the given request.
      # Action should represent what action is being requested (such as GET on a route)
      # Object is the object the action is being requested on (such as the route '/admin')
      def match?(action, object)
        true
      end

      def permit?(user, request, params)
        return true if allow_all?
        return false if deny_all?
        return allow_by_default || !deny_by_default if allow.empty? && deny.empty?
        allowed?(user, request, params) && (prefer_allow? || !denied?(user, request, params))
      end

      def allowed?(user, request, params)
        return allow_by_default && !denied?(user, request, params) if allow.empty?
        allow.any? { |m| m.match?(user, request, params) }
      end

      def denied?(user, request, params)
        return deny_by_default && !allowed?(user, request, params) if deny.empty?
        deny.any? { |m| m.match?(user, request, params) }
      end
    end
  end
end
