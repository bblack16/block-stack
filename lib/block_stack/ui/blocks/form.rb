module BlockStack
  class Form < Block

    def default_locals
      {
        model:         nil,
        form:          nil,
        name:          'form',
        save_text:     nil,
        save_to:       '/dformed',
        method:        :post,
        save_redirect: nil,
        df_class:      nil
      }
    end

  end
end
