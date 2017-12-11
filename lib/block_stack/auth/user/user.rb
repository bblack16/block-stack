module BlockStack
  class User
    include BBLib::Effortless
    attr_str :name, arg_at: 0, dformed_attributes: { label: '<i class="fa fa-user-circle"/>Username' }
    attr_str :display_name, default_proc: :name, dformed: false
    attr_ary_of String, :roles, default: [], pre_proc: proc { |x| [x].flatten.map(&:to_s) }, uniq: true, dformed: false
    attr_hash :attributes, default: {}, dformed: false
    attr_str :password, dformed_attributes: { type: :password }
    attr_str :email, dformed_attributes: { type: :email }
    attr_str :phone #, dformed_attributes: { type: :phone }
    attr_time :last_login, default: nil, allow_nil: true, dformed: false
    attr_time :current_login, default: nil, allow_nil: true, dformed: false
    attr_int :login_count, default: 0, dformed: false
    attr_int :expiration, default: nil, allow_nil: true, singleton: true, pre_proc: proc { |x| x.is_a?(String) || x.is_a?(Symbol) ? x.to_s.parse_duration : x }
    attr_sym :encrypt_password, default: :sha2, allow_nil: true, singleton: true

    init_type :loose

    def admin?
      role?(:admin)
    end

    def role?(name)
      roles.include?(name.to_s)
    end

    def expired?
      return false unless self.class.expiration
      return true unless current_login
      Time.now - self.class.expiration > current_login
    end

    def save
      # if !exist? && self.class.encrypt_password
      #   self.password = Encryption.encrypt(password, self.class.encrypt_password)
      # end
      if defined?(BlockStack::Model) && self.is_a?(BlockStack::Model)
        super
      else
        true
      end
    end
  end
end
