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

      def changes?
        !diff.empty?
      end

      def reset
        self.original = object.serialize.dup
      end
    end
  end
end
