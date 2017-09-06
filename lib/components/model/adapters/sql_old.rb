require 'sequel'

module BlockStack
  module Models
    class SQL
      include BlockStack::Model

      class << self
        before :all, :find_all, :find, :first, :last, :sample, :count, :exist?, :create_table_if_not_exist
      end

      before :save, :delete, :exist?, :create_table_if_not_exist

      def self._current_model(model = nil)
        @model = model if model
        @model
      end

      def self.missing_columns
        return [] unless table_exist?
        attr_columns.map { |a| a[:name] } - dataset.columns
      end

      def self.extra_columns
        return [] unless table_exist?
        dataset.columns - attr_columns.map { |a| a[:name] }
      end

      def self.attr_columns
        _attrs.map do |name, data|
          next if data[:options].include?(:serialize) && !data[:options][:serialize]
          if data[:options][:sql_type]
            method = data[:options][:sql_type]
          else
            method = case data[:type]
            when :string, :integer, :float, :array, :date, :boolean
              data[:type]
            when :dir, :file, :symbol
              :string
            when :integer_between
              :integer
            when :float_between
              :float
            when :time
              :timestamp
            when :element_of
              :string
            when :hash
              :json
            when :of
              sql_column_type_for(*data[:options][:classes])
            when :array_of
              :array
            else
              :text
            end
          end
          { type: method, name: name, options: data[:sql] || {} }
        end.compact
      end

      def self.find(query)
        query = { id: query } unless query.is_a?(Hash)
        # debug { dataset.where(query).sql }
        dataset.where(query).first
      end

      def self.build_filter(opts)
        opts[:sort] = opts[:order] if opts[:order]
        dataset.limit(opts[:limit]).offset(opts[:offset]).order(opts[:sort])
      end

      def self.all(opts = {})
        build_filter(opts).all
      end

      def self.find_all(query, opts = {})
        filter = build_filter(opts)
        query = query.keys_to_sym if query.is_a?(Hash)
        # debug { filter.where(query).sql }
        filter.where(query).all
      end

      def self.first(query = nil, opts = {})
        # debug { dataset.limit(1).sql }
        dataset.limit(1).first
      end

      def self.last
        # debug { dataset.limit(1).order(Sequel.desc(:id)).sql }
        dataset.order(:id).last
      end

      def self.count(query = {})
        # debug { "SELECT COUNT(*) FROM #{dataset_name}" }
        dataset.where(query).count
      end

      def self.average(field, query = {})
        dataset.where(query).avg(field)
      end

      def self.min(field, query = {})
        dataset.where(query).min(field)
      end

      def self.max(field, query = {})
        dataset.where(query).max(field)
      end

      def self.sum(field, query = {})
        dataset.where(query).sum(field)
      end

      def self.distinct(field, query = {})
        dataset.select(field).where(query).distinct.all.map { |i| i[field.to_sym] }
      end

      def self.latest_by(field, count, query = {})
        dataset.where(query).order(field).limit(count).all
      end

      def self.oldest_by(field, count, query = {})
        dataset.where(query).order(field).limit(count).all
      end

      def self.table_exist?
        @_table_exist ||= db.tables.include?(dataset_name)
      end

      def save
        if exist?
          debug { dataset.where(id: id).update_sql(serialize_for_sql) }
          dataset.where(id: id).update(serialize_for_sql)
        else
          debug { dataset.insert_sql(serialize_for_sql) }
          dataset.insert(serialize_for_sql)
        end
      end

      def serialize_for_sql
        serialize.hmap do |k, v|
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
      end

      def self.instantiate(result)
        return nil unless result
        return result if result.class == self
        result = result.hmap do |k, v|
          [
            k.to_sym,
            if _attrs[k.to_sym] && [:hash, :array, :array_of].any? { |t| t == _attrs[k.to_sym][:type] } && v.is_a?(String)
              JSON.parse(v)
            else
              v
            end
          ]
        end
        self.new(result)
      end

      def delete
        debug { dataset.where(id: id).delete_sql }
        dataset.where(id: id).delete
      end

      def self.create_table_if_not_exist
        if table_exist?
          create_missing_columns unless @_columns_checked
          return true
        end
        logger.info("Creating table for #{self}: #{dataset_name} (#{attr_columns.size} columns)")
        BlockStack::Models::SQL._current_model(self)
        db.create_table?(dataset_name) do |t|
          BlockStack::Models::SQL._current_model.attr_columns.each do |config|
            BlockStack.logger.debug("Adding column to database: #{config[:name]} (#{config[:type]}, options = #{config[:options]})")
            t.send(config[:type], config[:name], config[:options])
          end
        end
        debug("Table #{dataset_name} created.")
        table_exist?
      end

      def self.create_missing_columns
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

      def self.drop_extra_columns
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

      def self.sql_column_type_for(*klasses)
        matches = klasses.flat_map do |klass|
          match = SQL_COLUMN_MAPPING.find { |k, v| v.any? { |c| klass <= c } }&.first || :text
        end.unique
        return matches.first if matches.size == 1
        :text
      end

      protected

      def create_table_if_not_exist
        self.class.create_table_if_not_exist
      end
    end
  end
end
