module BlockStack
  class Card < Block

    def default_locals(custom = {})
      {
        title:     custom[:model] ? custom[:model].title : '',
        subtitle:  custom[:model] ? custom[:model].tagline : nil,
        image:     custom[:model] ? custom[:model].thumbnail : nil,
        content:   custom[:model] ? nil : nil, # TODO Replace nil with something else
        link:      custom[:model] ? custom[:model].link_for(:show).attributes[:href] : nil
      }
    end

  end
end
