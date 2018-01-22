require_relative 'param'

module BlockStack
  module Authentication
    class HTMLForm < Param

      def credentials(request, params)
        return false unless request.form_data?
        super
      rescue => _e
        false
      end
    end
  end
end
