module BlockStack
  class Details < Block

    def default_locals
      {
        title: '',
        data:  {}
      }
    end

    def default_attributes
      {
        class: 'details'
      }
    end

  end
end
