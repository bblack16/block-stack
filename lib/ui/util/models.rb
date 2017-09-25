module BlockStack
  # Methods related to block stack models.
  module ModelHelper

    def name_for(model)
      if model.is_a?(Model)
        model.setting?(:title_attribute) ? model.attribute(model.setting(:title_attribute)) : "#{model.class.clean_name} #{model.id}"
      else
        model.to_s.title_case
      end
    end

  end
end
