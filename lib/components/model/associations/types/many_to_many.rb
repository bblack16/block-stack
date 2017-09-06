module BlockStack
  module Associations
    class ManyToMany < Association
      attr_sym :through, required: true
      attr_of Object, :through_model, serialize: false
      attr_sym :through_attribute, :through_column, serialize: false

      before :through_model, :through_attribute, :through_column, :lookup_through_model

      def associated?(obj_a, obj_b)
        return false if obj_a == obj_b
        ary = [obj_a, obj_b]
        b = ary.find { |m| m.is_a?(model) }
        a = ary.find { |m| m.is_a?(BlockStack::Model.model_for(from)) }
        return false unless a && b
        through_model.find(through_attribute => a.attribute(attribute), through_column => b.attribute(column))
      end

      def associate(obj_a, *objs)
        [objs].flatten.compact.all? do |obj_b|
          if associated?(obj_a, obj_b)
            true
          else
            through_model.create(through_attribute => obj_a.attribute(attribute), through_column => obj_b.attribute(column))
          end
        end
      end

      def disassociate(obj_a, obj_b)
        through_model.find_all(through_attribute => obj_a.attribute(attribute), through_column => obj_b.attribute(column)).all? { |i| i.delete }
      end

      def retrieve(obj)
        join_ids = through_model.find_all(through_attribute => obj.attribute(attribute)).map { |r| r.attribute(through_column) }.uniq
        return [] unless join_ids && !join_ids.empty?
        model.find_all(column => join_ids)
      end

      # Many to many does not cascade when deleting
      def delete(obj)
        true
      end

      def opposite
        ManyToMany.new(
          from: to,
          to: from,
          column: attribute,
          attribute: column,
          through: through
        )
      end

      protected

      def simple_init(*args)
        super
        named = BBLib.named_args(*args)
        self.attribute = named[:attribute] || :id
        self.column = named[:column] || :id
      end

      def lookup_through_model
        @through_model     = BlockStack::Model.model_for(through) unless @through_model
        @through_attribute = ("#{BlockStack::Model.model_for(from).model_name}_id".to_sym rescue nil) unless @through_attribute
        @through_column    = ("#{BlockStack::Model.model_for(to).model_name}_id".to_sym rescue nil) unless @through_column
      end

    end
  end
end
