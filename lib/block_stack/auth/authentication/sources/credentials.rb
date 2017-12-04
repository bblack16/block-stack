module BlockStack
  module Authentication
    class Credentials < Source
      attr_sym :user_param, default: :user
      attr_sym :pass_param, default: :password

      def credentials(request, params)
        hash = request.body.read.split('&').hmap do |param|
          param.split('=', 2)
        end.keys_to_sym
        user = hash[user_param]
        pass = hash[pass_param]
        return false unless user && pass && !user.empty? && !pass.empty?
        [user, pass]
      rescue => e
        false
      end

    end
  end
end
