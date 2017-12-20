module BlockStack
  module Authentication
    class Param < Source
      attr_sym :param, default: :api_key

      def credentials(request, params)
        return false unless params.include?(param) && !params[param].empty?
        params[param]
      end

    end
  end
end
