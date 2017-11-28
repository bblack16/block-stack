module BlockStack
  class Header < Block

    def default_locals
      {
        title:      '',
        subtitle:   nil,
        background: nil,
        color:      :blue,
        animated:   true
      }
    end

  end
end
