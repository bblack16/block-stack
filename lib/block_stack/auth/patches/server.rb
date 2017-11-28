module BlockStack
  class Server
    enable :sessions

    def authorized?
      @auth ||=  Rack::Auth::Basic::Request.new(request.env)
      @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == ["bblack","test"]
    end

    def protected!
      unless authorized?
        response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
        halt 401, "You must provide valid credentials\n"
      end
    end

    before do
      protected!
    end
  end
end
