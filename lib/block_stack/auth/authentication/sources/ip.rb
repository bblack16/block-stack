module BlockStack
  module Authentication
    class Ip < Source

      def credentials(request, params)
        request.ip
      end

    end
  end
end
