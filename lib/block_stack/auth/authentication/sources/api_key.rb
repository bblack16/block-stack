module BlockStack
  module Authentication
    class ApiKey < Source
      attr_sym :param, default: :api_key

      def credentials(request, params)
        return false unless params.include?(param) && !params[param].empty?
        [params[param]].map{ |v| [v, v] }
      end

    end
  end
end
