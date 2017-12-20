module BlockStack
  module Helpers
    module UserAuth
      def custom_unauthenticated!
        redirect config.login || '/login', 302, notice: 'Please login'
      end
    end
  end
end
