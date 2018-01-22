module BlockStack
  module Helpers
    module CAS
      def custom_unauthenticated!
        halt 401, 'You must authenticate first.' unless session['cas'] && session['cas']['user']
        session[:login] = config.cas_login_class.new(name: session['cas']['user'], extra_attributes: session['cas']['extra_attributes']) unless session[:login]
      end
    end
  end
end
