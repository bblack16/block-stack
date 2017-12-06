module BlockStack
  module Model
    class ChangeSet
      include BBLib::Effortless
      attr_hash :original
      attr_of BBLib::Effortless, :object, arg_at: 0

      after :object=, :reset

      def diff
        return object.serialize unless object.exist?
        object.serialize.hmap do |k, v|
          if v == original[k]
            nil
          else
            [k, v]
          end
        end
      end

      alias changes diff

      def changes?
        !diff.empty? || associations_changed?
      end

      def reset
        self.original = object.serialize.dup.hmap { |k, v| [k, (v.dup rescue v)] }
      end

      def associations_changed?
        return true unless object.exist?
        old_obj = object.class.find(object.id)
        object.associations.any? do |association|
          name = association.method_name
          object.send(name) != old_obj.send(name)
        end
      end
    end
  end
end
