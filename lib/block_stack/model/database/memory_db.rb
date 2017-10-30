module BlockStack
  module Database
    class MemoryDb
      include BBLib::Effortless

      attr_hash :db, default: {}
      attr_hash :ids, default: Hash.new(0)

      def dataset(name)
        db[name]
      end

      alias_method :[], :dataset

      def save(dataset, obj)
        return obj.id if db[dataset] && db[dataset].include?(obj)
        (db[dataset] ||= []) << obj
        obj.id = ids[dataset] += 1
      end

      def delete(dataset, obj)
        db[dataset].delete(obj)
      end

    end
  end
end
