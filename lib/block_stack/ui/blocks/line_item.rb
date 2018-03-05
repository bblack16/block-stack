module BlockStack
  class LineItem < Block

    def default_locals(custom = {})
      {
        title:     '',
        subtitle:  nil,
        image:     nil,
        content:   nil,
        link:      nil
      }
    end

  end
end
