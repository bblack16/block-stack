# This provider always returns a user with the provided name. Essentially it
# requires a user to input a name but does not care about passwords.
# Useful only for testing, not for production.
module BlockStack
  module Authentication
    class Allow < Provider

    end
  end
end
