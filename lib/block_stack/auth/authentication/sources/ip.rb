module BlockStack
  module Authentication
    class Ip < Source

      def credentials(request, params)
        puts "IP: #{request.ip}"
        [request.ip].map { |a| [a, a] }
      end

    end
  end
end
