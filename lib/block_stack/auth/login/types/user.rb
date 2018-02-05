require_relative 'protected_login'

module BlockStack
  module Authentication
    class User < ProtectedLogin

      attr_str :email, dformed_attributes: { type: :email }

    end
  end
end
