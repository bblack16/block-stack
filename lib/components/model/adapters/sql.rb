require 'sequel'

module BlockStack
  module Models
    module SQL
      def self.included(base)
        base.extend ClassMethods
        base.send(:include, BlockStack::Model)
        base.send(:include, InstanceMethods)
        base.singleton_class.send(:before, :all, :find_all, :find, :first, :last, :sample, :count, :exist?, :create_table_if_not_exist)
        # base.send(:after, :delete, :delete_associations)
        base.send(:before, :save, :delete, :exist?, :create_table_if_not_exist)
      end

      def self._current_model(model = nil)
        @model = model if model
        @model
      end

      module ClassMethods

        def missing_columns
          return polymorphic_model.missing_columns if is_polymorphic_child?
          return [] unless table_exist?
          attr_columns.map { |a| a[:name] } - dataset.columns
        end

        def extra_columns
          return polymorphic_model.extra_columns if is_polymorphic_child?
          return [] unless table_exist?
          dataset.columns - attr_columns.map { |a| a[:name] }
        end

        def attr_columns
          return polymorphic_model.attr_columns if is_polymorphic_child?
          attrs = _attrs
          if polymorphic
            children = {}
            descendants.each { |d| children = children.merge(d._attrs) }
            attrs = children.merge(attrs).merge(_class: { type: :string, options: { serialize: true } })
          end
          attrs.map do |name, data|
            next if data[:options].include?(:serialize) && !data[:options][:serialize]
            if data[:options][:sql_type]
              method = data[:options][:sql_type]
            else
              method = case data[:type]
              when :string, :integer, :float, :date, :boolean
                data[:type]
              when :dir, :file, :symbol
                :tring
              when :integer_between
                :integer
              when :float_between
                :float
              when :time
                :timestamp
              when :element_of
                :string
              when :elements_of, :array
                :string
              when :hash
                :json
              when :of
                sql_column_type_for(*data[:options][:classes])
              when :array_of
                :string
              else
                :text
              end.to_s.capitalize
            end
            { type: method, name: name, options: data[:sql] || {} }
          end.compact
        end

        def query_dataset
          if is_polymorphic_child?
            dataset.where(_class: self.to_s)
          else
            dataset
          end
        end

        def find(query)
          query = { id: query } unless query.is_a?(Hash)
          query_dataset.where(query).first
        end

        def build_filter(opts)
          opts[:sort] = opts[:order] if opts[:order]
          query_dataset.limit(opts[:limit]).offset(opts[:offset]).order(opts[:sort])
        end

        def all(opts = {})
          build_filter(opts).all
        end

        def find_all(query, opts = {})
          filter = build_filter(opts)
          query = query.keys_to_sym if query.is_a?(Hash)
          filter.where(query).all
        end

        def first
          query_dataset.limit(1).first
        end

        def last
          query_dataset.order(:id).last
        end

        def count(query = {})
          query_dataset.where(query).count
        end

        def average(field, query = {})
          query_dataset.where(query).avg(field)
        end

        def min(field, query = {})
          query_dataset.where(query).min(field)
        end

        def max(field, query = {})
          query_dataset.where(query).max(field)
        end

        def sum(field, query = {})
          query_dataset.where(query).sum(field)
        end

        def distinct(field, query = {})
          query_dataset.select(field).where(query).distinct.all.map { |i| i[field.to_sym] }
        end

        def latest_by(field, count, query = {})
          query_dataset.where(query).order(field).limit(count).all
        end

        def oldest_by(field, count, query = {})
          query_dataset.where(query).order(field).limit(count).all
        end

        def table_exist?
          return polymorphic_model.table_exist? if is_polymorphic_child?
          @_table_exist ||= db.tables.include?(dataset_name)
        end

        def custom_instantiate(result)
          return polymorphic_model.custom_instantiate(result) if is_polymorphic_child?
          return nil unless result
          return result if result.is_a?(Model)
          result = process_sql_hash(result)
          self.new(result)
        end

        def process_sql_hash(result)
          result.hmap do |k, v|
            [
              k.to_sym,
              if _attrs[k.to_sym] && ([:hash, :array, :array_of, :elements_of].any? { |t| t == _attrs[k.to_sym][:type] } || [_attrs[k.to_sym][:classes]].flatten.any? { |c| c.is_a?(Class) && c.ancestors.include?(BBLib::Effortless) }) && v.is_a?(String)
                JSON.parse(v)
              elsif v.is_a?(Sequel::Postgres::JSONArray)
                v.keys_to_sym
              else
                v
              end
            ]
          end
        end

        def create_table_if_not_exist
          return polymorphic_model.create_table_if_not_exist if is_polymorphic_child?
          if table_exist?
            create_missing_columns unless @_columns_checked
            return true
          end
          logger.info("Creating table for #{self}: #{dataset_name} (#{attr_columns.size} columns)")
          BlockStack::Models::SQL._current_model(self)
          db.create_table?(dataset_name) do
            BlockStack::Models::SQL._current_model.attr_columns.each do |config|
              BlockStack.logger.debug("Adding column to database: #{config[:name]} (#{config[:type]}, options = #{config[:options]})")
              send(config[:type], config[:name], config[:options])
            end
          end
          debug("Table #{dataset_name} created.")
          table_exist?
        end

        def create_missing_columns
          return polymorphic_model.create_missing_columns if is_polymorphic_child?
          if missing_columns.empty? || @_columns_checked
            @_columns_checked = true unless @_columns_checked
            return true
          end
          BlockStack::Models::SQL._current_model(self)
          db.alter_table(dataset_name) do |t|
            missing = BlockStack::Models::SQL._current_model.missing_columns
            BlockStack::Models::SQL._current_model.info("Attempting to create #{missing.size} missing #{'column'.pluralize(missing.size)}.")
            BlockStack::Models::SQL._current_model.attr_columns.each do |config|
              next unless missing.include?(config[:name])
              BlockStack::Models::SQL._current_model.info("Adding missing column to database: #{config[:name]} (#{config[:type]}, options = #{config[:options]})")
              add_column(config[:name], config[:type], config[:options])
            end
          end
        end

        def drop_extra_columns
          return polymorphic_model.drop_extra_columns if is_polymorphic_child?
          BlockStack::Models::SQL._current_model(self)
          db.alter_table(dataset_name) do |t|
            BlockStack::Models::SQL._current_model.extra_columns.each do |col|
              BlockStack::Models::SQL._current_model.info("Dropping column #{col}")
              drop_column col
            end
          end
        end

        SQL_COLUMN_MAPPING = {
          string:    [String, Symbol, File, Dir],
          timestamp: [Time, DateTime],
          datetime:  [Date],
          integer:   [Integer],
          float:     [Float],
          boolean:   [TrueClass, FalseClass],
          json:      [Hash],
          array:     [Array]
        }

        def sql_column_type_for(*klasses)
          matches = klasses.flat_map do |klass|
            match = SQL_COLUMN_MAPPING.find { |k, v| v.any? { |c| klass <= c } }&.first || :text
          end.unique
          return matches.first if matches.size == 1
          :text
        end
      end

      module InstanceMethods
        def save
          if exist?
            dataset.where(id: id).update(serialize_for_sql)
          else
            self.id = dataset.insert(serialize_for_sql)
            refresh
          end
          id ? true : false
        end

        def serialize_for_sql
          hash = serialize.hmap do |k, v|
            [
              k,
              if BBLib.is_a?(v, Array, Hash)
                v.to_json
              elsif BBLib.is_a?(v, Symbol)
                v.to_s
              else
                v
              end
            ]
          end
          hash.delete(:id) unless hash[:id]
          hash
        end

        def delete
          dataset.where(id: id).delete
        end

        protected

        def create_table_if_not_exist
          self.class.create_table_if_not_exist
        end
      end
    end
  end
end
