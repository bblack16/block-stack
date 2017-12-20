module BlockStack
  module Helpers
    module BasicAuth
      def custom_unauthenticated!
        headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
        halt 401, "Not authorized\n"
      end
    end
  end
end
