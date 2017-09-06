module BlockStack
  module Associations
    class OneToMany < OneToOne

      def retrieve(obj)
        model.find_all(column => obj.attribute(attribute))
      end

      def foreign_key
        false
      end

      def associate(obj_a, *objs)
        [objs].flatten.all? do |obj_b|
          if associated?(obj_a, obj_b)
            true
          else
            query = foreign_key? ? { attribute => obj_b.attribute(column) } : { column => obj_a.attribute(attribute) }
            (foreign_key? ? obj_a : obj_b).update(query)
          end
        end
      end

      def delete(obj)
        return true unless cascade?
        retrieve(obj).all?(&:delete)
      end

      def opposite
        ManyToOne.new(
          from: to,
          to: from,
          column: attribute,
          attribute: column,
          foreign_key: true
        )
      end

      protected

      def simple_init(*args)
        super
        named = BBLib.named_args(*args)
        self.attribute = named[:attribute] || :id
        self.column = named[:column] || "#{from.singularize}_id".to_sym
      end

      def method_name_default
        to
      end

    end
  end
end
