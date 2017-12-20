module BlockStack
  module Authentication
    class Role
      include BBLib::Effortless

      attr_sym :name, required: true, arg_at: 0
      attr_str :display_name, default_proc: proc { |x| x.name.to_s }
      attr_str :description

    end
  end
end
