module BlockStack
  class MenuItem
    attr_ary_of Role, :roles
    attr_bool :logged_in, default: false

    def authorized?(user)
      return true if roles.empty?
      return logged_in? unless user
      return roles.any? { |role| user.role?(role) }
    end
  end
end
