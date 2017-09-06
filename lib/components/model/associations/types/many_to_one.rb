module BlockStack
  module Associations
    class ManyToOne < OneToOne

      # Many to one does not perform cascading delete
      def delete(obj)
        return true
      end

      def foreign_key
        true
      end

      def opposite
        OneToMany.new(
          from: to,
          to: from,
          column: attribute,
          attribute: column,
          foreign_key: false
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
