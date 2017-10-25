module BlockStack
  module Models
    module Memory
      def self.included(base)
        base.extend ClassMethods
        base.send(:include, BlockStack::Model)
        base.send(:include, InstanceMethods)
      end

      module ClassMethods

        def find(query)
          query = { id: query } unless query.is_a?(Hash)
          find_all(query).first
        end

        def all(opts = {})
          instances.select { |i| i.id }
        end

        def find_all(query, opts = {})
          instances.find_all do |i|
            run_query(i, query)
          end
        end

        # def first
        #   query_dataset.limit(1).first
        # end
        #
        # def last
        #   query_dataset.order(:id).last
        # end
        #
        # def count(query = {})
        #   query_dataset.where(query).count
        # end
        #
        # def average(field, query = {})
        #   query_dataset.where(query).avg(field)
        # end
        #
        # def min(field, query = {})
        #   query_dataset.where(query).min(field)
        # end
        #
        # def max(field, query = {})
        #   query_dataset.where(query).max(field)
        # end
        #
        # def sum(field, query = {})
        #   query_dataset.where(query).sum(field)
        # end
        #
        # def distinct(field, query = {})
        #   query_dataset.select(field).where(query).distinct.all.map { |i| i[field.to_sym] }
        # end
        #
        # def latest_by(field, count, query = {})
        #   query_dataset.where(query).order(field).limit(count).all
        # end
        #
        # def oldest_by(field, count, query = {})
        #   query_dataset.where(query).order(field).limit(count).all
        # end

        def custom_instantiate(result)
          return polymorphic_model.custom_instantiate(result) if is_polymorphic_child?
          return nil unless result
          return result if result.is_a?(Model)
          self.new(result)
        end

        protected

        def run_query(obj, query)
          query.all? do |k, v|
            query_check(v, obj.attribute(k))
          end
        end

        def query_check(exp, value)
          case exp
          when Regexp
            exp =~ value.to_s
          when Range
            exp === value
          when String
            exp == value.to_s
          else
            exp == value
          end
        end
      end

      module InstanceMethods
        # In Memory objects are never saved.
        # true is always returned but nothing will persist over a restart.
        def save
          self.id = object_id
          true
        end

        # Garbage collection manages in memory objects. Delete does nothing.
        # false will always be returned but does not signify anything.
        def delete
          false
        end
      end
    end
  end
end
