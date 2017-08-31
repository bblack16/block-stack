require 'mongo'

module BlockStack
  module Models
    class Mongo
      include BlockStack::Model
      attr_of BSON::ObjectId, :_id, serialize: false
      attr_bool :increment_id, default: true, singleton: true, dformed_field: false

      def self.all
        debug { "find().all()" }
        dataset.find.all
      end

      def self.find(query)
        query = {
          '$or': [
            { id: query },
            { _id: (BSON::ObjectId(query) rescue query) }
          ]
        } unless query.is_a?(Hash)
        debug { "find(#{query.to_json}).first()" }
        dataset.find(query).first
      end

      def self.find_all(query)
        query = convert_to_mongo_query(query)
        debug { "find(#{query.to_json}).all()" }
        dataset.find(query).map { |m| m }
      end

      def self.first(query = nil)
        query = convert_to_mongo_query(query)
        debug { "find(#{query.to_json}).first()" }
        dataset.find(query).first
      end

      def self.last(query = nil)
        query = convert_to_mongo_query(query)
        debug { "find(#{query.to_json}).last()" }
        dataset.find(query).last
      end

      def self.count
        debug { "find().count()" }
        dataset.find.count
      end

      def exist?
        self.class.exist?(index_keys)
      end

      def increment_id?
        self.class.increment_id?
      end

      def next_id
        self.class.next_id
      end

      def self.next_id
        ((dataset.find.sort(id: -1).limit(1).first[:id] rescue 0) || 0) + 1
      end

      def save
        body = Mongo.mongo_escape(save_attributes)
        if exist?
          debug { "update_one(#{index_keys}, #{body}, upsert: true)" }
          dataset.update_one(index_keys, body, upsert: true)
        else
          debug { "insert_one(#{body})" }
          dataset.insert_one(body)
        end
      end

      def retrieve_id
        return attribute(:id) if attribute(:id)
        next_id
      end

      def post_serialize(hash)
        hash.merge(increment_id? ? { id: retrieve_id } : {})
      end

      def index_keys
        if increment_id?
          { id: retrieve_id }
        else
          { _id: attribute(:_id) } if attribute(:_id)
        end
      end

      def delete
        debug { "delete_one({ _id: #{attribute(:_id)} })" }
        dataset.delete_one({ _id: attribute(:_id) }).deleted_count == 1
      end

      def self.mongo_escape(hash)
        if hash.is_a?(Hash)
          hash.hmap do |k, v|
            v = mongo_escape(v) if v.is_a?(Hash) || v.is_a?(Array)
            if k.to_s.include?('.')
              [k.to_s.gsub('.', '%2E'), v]
            else
              [k, v]
            end
          end
        elsif hash.is_a?(Array)
          hash.map { |h| mongo_escape(h) }
        else
          hash
        end
      end

      def self.mongo_unescape(hash)
        if hash.is_a?(Hash)
          hash.hmap do |k, v|
            v = mongo_unescape(v) if v.is_a?(Hash) || v.is_a?(Array)
            if k.to_s.include?('%2E')
              [k.to_s.gsub('%2E', '.'), v]
            else
              [k, v]
            end
          end.keys_to_sym
        elsif hash.is_a?(Array)
          hash.map { |h| mongo_unescape(h) }.keys_to_sym
        else
          hash
        end
      end

      def self.convert_to_mongo_query(query)
        return query unless query.is_a?(Hash)
        query.hmap do |k, v|
          [
            k,
            if v.is_a?(Array)
              { '$in': v }
            else
              v
            end
          ]
        end
      end

      protected

      def self.instantiate(hash)
        return hash if hash.class == self
        return nil unless hash.is_a?(Hash)
        self.new(mongo_unescape(hash))
      end
    end
  end
end
