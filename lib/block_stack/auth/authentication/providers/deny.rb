# This provider never authenticates a user no matter what. It is only useful
# for certain testing scenarios.
module BlockStack
  module Authentication
    class Deny < Provider

      # Always returns nil
      def authenticate(id, secret = nil, request: {}, params: {})
        nil
      end

    end
  end
end
