module BlockStack
  module Helpers
    module Server
      def format
        formatter = pick_formatter(request, params)
        formatter ? [formatter.format].flatten.first : :html
      end
    end
  end
end
