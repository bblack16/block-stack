module BlockStack
  module Associations
    class OneToMany < Association

      attr_set :cascade, default: false
      attr_bool :singular, default: false

      def associated?(obj_a, obj_b)
        return false if obj_a == obj_b
        obj_b.attribute(column) == obj_a.attribute(attribute)
      end

      def retrieve(obj)
        return [] unless obj.id
        model.find_all(column => obj.attribute(attribute))
      end

      def associate(obj_a, *objs)
        objs = [objs].flatten.map { |o| o.is_a?(Model) ? o : model.find(o) }
        retrieve(obj_a).each { |o| disassociate(obj_a, o) unless objs.include?(o) }
        objs.all? do |obj_b|
          if associated?(obj_a, obj_b)
            true
          else
            query = { column => obj_a.attribute(attribute) }
            obj_b.update(query)
          end
        end
      end

      def disassociate(obj_a, obj_b)
        return true unless associated?(obj_a, obj_b)
        obj_b.update(column => nil)
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
          attribute: column
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
