module BlockStack
  module Authentication
    class Basic < Source

      def credentials(request, params)
        return false unless request.request_method != 'POST'
        auth = Rack::Auth::Basic::Request.new(request.env)
        return false unless auth.provided? && auth.basic? && auth.credentials
        auth.credentials
      end

    end
  end
end
