module BlockStack
  class Card < Block

    def default_locals
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
