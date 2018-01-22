module BlockStack
  module Helpers
    module UserAuth
      def custom_unauthenticated!
        if session[:auth_provided]
          redirect config.login || '/login', 302, notice: 'Invalid credentials. Please try again.', severity: :warn
        else
          redirect config.login || '/login', 302, notice: 'Please login first.'
        end
      end
    end
  end
end
