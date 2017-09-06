module BlockStack
  module Associations
    class OneThroughOne < ManyToMany

      def associate(obj_a, obj_b)
        return true if associated?(obj_a, obj_b)
        disassociate_all(obj_a)
        through_model.create(through_attribute => obj_a.attribute(attribute), through_column => obj_b.attribute(column))
      end

      def retrieve(obj)
        join_id = through_model.find(through_attribute => obj.attribute(attribute))&.attribute(through_column)
        return nil unless join_id
        model.find(column => join_id)
      end

      def delete(obj)
        return true unless cascade?
        retrieve(obj)&.delete
      end

      def opposite
        OneThroughOne.new(
          from: to,
          to: from,
          column: attribute,
          attribute: column,
          through: through
        )
      end

      protected

      def method_name_default
        to&.singularize
      end

    end
  end
end
