module BlockStack
  class Header < Block

    def default_locals
      {
        title:      '',
        subtitle:   nil,
        background: nil,
        thumbnail:  nil,
        icon:       nil,
        color:      :blue,
        animated:   true
      }
    end

  end
end
