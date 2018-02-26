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

  class VerticalCard < Card

  end
end
