module BlockStack
  module Authentication
    class Credentials < Source # TODO Change to HTML Form
      attr_sym :user_param, default: :user
      attr_sym :pass_param, default: :password

      def credentials(request, params)
        # TODO Fix encoding issues from HTML forms
        hash = request.body.read.split('&').hmap do |param|
          CGI.unescapeHTML(param).split('=', 2)
        end.keys_to_sym
        user = hash[user_param]
        pass = hash[pass_param]
        return false unless user && pass && !user.empty? && !pass.empty?
        [user, pass]
      rescue => e
        false
      end

      protected

      def simple_setup
        require 'cgi' unless defined?(CGI)
      end

    end
  end
end
