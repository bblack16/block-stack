module BlockStack
  module Authentication
    class LDAPLogin < Login
      attr_str :dn, :email, :phone, :title, :company, :manager
      attr_str :location, :department, :description
      attr_ary_of [String], :member_of

    end
  end
end
