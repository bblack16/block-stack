module BlockStack
  class Card < Block

    def default_locals
      {
        title:     '',
        subtitle:  nil,
        image:     nil,
        thumbnail: nil,
        content:   nil,
        style:     :default,
        width:     '300px',
        height:    nil
      }
    end

  end
end
