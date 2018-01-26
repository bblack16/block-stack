module BlockStack
  class MenuItem
    attr_ary_of Authorization::Base, :authorizations
    attr_bool :logged_in, default: false

    def authorized?(user, request, params)
      return true if authorizations.empty?
      return logged_in? unless user
      authorizations.any? do |authorization|
        authorization.permit?(user, request, params)
      end
    end
  end
end
