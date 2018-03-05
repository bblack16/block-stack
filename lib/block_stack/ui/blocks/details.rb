module BlockStack
  class Details < Block

    def default_locals(custom = {})
      {
        title: custom[:model] ? custom[:model].title : '',
        data:  custom[:model] ? custom[:model].serialize.hmap { |k, v| [k.to_s.gsub('_', ' ').title_case, v] } : {}
      }
    end

    def default_attributes
      {
        class: 'details'
      }
    end

  end
end
