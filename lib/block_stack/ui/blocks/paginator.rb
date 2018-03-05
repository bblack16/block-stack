module BlockStack
  class Paginator < Block

    def default_locals(custom = {})
      {
        page_count: 10,
        param: :page,
        size: 7
      }
    end

  end
end
