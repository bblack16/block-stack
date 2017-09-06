require 'mongo'

Mongo::Logger.logger = BlockStack.logger

module BlockStack
  module Models
    module Mongo
      def self.included(base)
        base.extend ClassMethods
        base.send(:include, BlockStack::Model)
        base.send(:include, InstanceMethods)
        base.send(:attr_of, BSON::ObjectId, :_id, serialize: false, blockstack: { display: false })
        base.send(:attr_bool, :increment_id, default: true, singleton: true, dformed_field: false)
      end

      module ClassMethods
        def all(opts = {})
          debug { "find().all()" }
          build_filter(dataset.find, opts).to_a
        end

        def build_filter(query, opts)
          opts[:sort] = opts[:order] if opts[:order]
          opts[:sort] = [opts[:sort]].flatten.map { |f| [f, 1] }.to_h if opts[:sort] && !opts[:sort].is_a?(Hash)
          query = query.limit(opts[:limit]) if opts[:limit]
          query = query.skip(opts[:offset]) if (opts[:offset] ||= opts[:skip])
          query = query.sort(opts[:sort]) if opts[:sort]
          query
        end

        def query_dataset(query = nil)
          query = (query || {}).merge(_class: self.to_s) if is_polymorphic_child?
          query ? dataset.find(query) : dataset.find
        end

        def find(query)
          query = {
            '$or': [
              { id: query.to_s.to_i },
              { _id: (BSON::ObjectId(query) rescue query) }
            ]
          } unless query.is_a?(Hash)
          query_dataset(query).first
        end

        def find_all(query, opts = {})
          return all if query.nil? || query.empty?
          query = convert_to_mongo_query(query)
          build_filter(query_dataset(query), opts).to_a
        end

        def first
          query_dataset.first
        end

        def last
          query_dataset.sort('$natural': -1).first
        end

        def count
          query_dataset.count
        end

        def average(field, query = {})
          BBLib.average(query_dataset(query).distinct(field).to_a)
        end

        def min(field, query = {})
          query_dataset(query).sort(field => 1).limit(1).first[field]
        end

        def max(field, query = {})
          query_dataset(query).sort(field => -1).limit(1).first[field]
        end

        def sum(field, query = {})
          query_dataset(query).distinct(field).to_a.sum
        end

        def distinct(field, query = {})
          query_dataset.distinct(field)
        end

        def next_id
          ((dataset.find.sort(id: -1).limit(1).first[:id] rescue 0) || 0) + 1
        end

        def mongo_escape(hash)
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

        def mongo_unescape(hash)
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

        def convert_to_mongo_query(query)
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

        def custom_instantiate(hash)
          return polymorphic_model.custom_instantiate(hash) if is_polymorphic_child?
          return hash if hash.class == self
          return nil unless hash.is_a?(Hash)
          self.new(mongo_unescape(hash))
        end
      end

      module InstanceMethods
        def exist?
          self.class.exist?(index_keys)
        end

        def increment_id?
          self.class.increment_id?
        end

        def next_id
          self.class.next_id
        end

        def save
          body = self.class.mongo_escape(serialize_attributes)
          result = if exist?
            dataset.update_one(index_keys, body, upsert: true).ok?
          else
            dataset.insert_one(body).ok?
          end
          refresh
          result
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
            self.id = retrieve_id unless id
            { id: id }
          else
            { _id: attribute(:_id) } if attribute(:_id)
          end
        end

        def delete
          dataset.delete_one({ _id: attribute(:_id) }).deleted_count == 1
        end
      end
    end
  end
end
