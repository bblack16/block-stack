module BlockStack
  module Associations
    class ManyToOne < OneToOne

      attr_bool :singular, default: true

      # Many to one does not perform cascading delete
      def delete(obj)
        return true
      end

      def associate(obj_a, obj_b)
        obj_b = model.find(obj_b) unless obj_b.is_a?(Model)
        return false unless obj_a && obj_b
        return true if associated?(obj_a, obj_b)
        query = { attribute => obj_b.attribute(column) }
        obj_a.update(query)
      end

      def opposite
        OneToMany.new(
          from: to,
          to: from,
          column: attribute,
          attribute: column
        )
      end

      protected

      def simple_init(*args)
        super
        named = BBLib.named_args(*args)
        self.attribute = named[:attribute] || "#{to.singularize}_id".to_sym
        self.column = named[:column] || :id
      end

      def method_name_default
        to&.singularize
      end

    end
  end
end
