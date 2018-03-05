module BlockStack
  class Table < Block

    def default_locals(custom = {})
      {
        data:        [],
        headers:     nil,
        max:         256,
        empty:       nil,
        page_length: 25
      }
    end

    def default_attributes
      {
        class: 'data-table default responsive'
      }
    end

  end
end
