require_relative 'model_associations'
require_relative 'validation/validation'
require_relative 'exceptions/invalid_model'
require_relative 'exceptions/invalid_association'
require_relative 'changeset'
require_relative 'cache/cache'

####################
# Features
####################
# *Dynamic database types
# *Support as mixin
# *Default query method support
# *Name conventions (pluralization)
# *Arbitrary config support
# Polymorphic model support
# Basic search support
# Block support for query methods that return arrays
# Unified query language for all adapters (using hashes most likely)
# *Model uniqueness (by fields other than id or by multiple fields)
# Full dformed support (when UI is available only!)
# *Changeset based updating


module BlockStack
  module Model

    def self.included(base)
      included_classes.push(base)
      base.send(:include, BBLib::Effortless)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)
      base.extend(Associations)

      base.singleton_class.send(:after, :all, :find_all, :search, :instantiate_all, send_value_ary: true, modify_value: true)
      base.singleton_class.send(:after, :find, :first, :last, :sample, :instantiate, send_value: true, modify_value: true)
      base.singleton_class.send(:before, :all, :find, :find_all, :search, :first, :last, :sample, :_check_cache, try_first: true, send_method: true)
      base.singleton_class.send(:after, :all, :find, :find_all, :search, :first, :last, :sample, :_add_cache, send_all: true)
      base.send(:attr_int, :id, default: nil, allow_nil: true, sql_type: :primary_key, dformed: false, searchable: true)
      base.send(:attr_time, :created_at, :updated_at, default_proc: proc { Time.now }, dformed: false, blockstack: { display: false })
      base.send(:attr_of, BBLib::HashStruct, :configuration, default_proc: proc { |x| x.ancestor_config }, singleton: true)
      base.send(:attr_of, ChangeSet, :change_set, default_proc: proc { |x| ChangeSet.new(x) }, serialize: false, dformed: false)
      base.send(:attr_ary_of, Validation, :validations, default: [], singleton: true)
      base.send(:attr_hash, :errors, default: {}, serialize: false, dformed: false)
      base.send(:bridge_method, :config, :db, :model_name, :clean_name, :plural_name, :dataset_name, :validations)

      base.load_associations

      ##########################################################
      # Add basic implementations of query methods
      # Only if they are not already defined by the adapter or class
      ##########################################################
      base.instance_eval do
        def find(query)
          query = { id: query } unless query.is_a?(Hash)
          find_all(query).first
        end unless respond_to?(:find)

        def [](id)
          find(id)
        end unless respond_to?(:[])

        def find_all(query, &block)
          raise AbstractError, 'This method should have been defined in a sub class.'
        end unless respond_to?(:find_all)

        def all(&block)
          raise AbstractError, 'This method should have been defined in a sub class.'
        end unless respond_to?(:all)

        def first
          all.first
        end unless respond_to?(:first)

        def last
          all.last
        end unless respond_to?(:last)

        def count(query = {})
          query.nil? || query.empty? ? all.size : find_all(query).size
        end unless respond_to?(:count)

        def average(field, query = {})
          BBLib.average(find_all(query).map { |i| i.attribute(field) })
        end unless respond_to?(:average)

        def min(field, query = {})
          find_all(query).map { |i| i.attribute(field) }.min
        end unless respond_to?(:min)

        def max(field, query = {})
          find_all(query).map { |i| i.attribute(field) }.max
        end unless respond_to?(:max)

        def distinct(field, query = {})
          find_all(query).map { |i| i.attribute(field) }.uniq
        end unless respond_to?(:distinct)

        def sum(field, query = {})
          find_all(query).map { |i| i.attribute(field) }.sum
        end unless respond_to?(:sum)

        def sample(query = {})
          query ? find_all(query).sample : all.sample
        end unless respond_to?(:sample)

        def exist?(query = {})
          query = { id: query } unless query.is_a?(Hash)
          (query && find(query) != nil) ? true : false
        end unless respond_to?(:exist?)
      end
    end

    def self.Dynamic(db = Database.db)
      raise RuntimeError, 'No database has been configured. Models cannot be dynamically loaded.' unless db
      BlockStack::Adapters.by_client(db.class)
    end

    def self.next_db
      @next_db
    end

    def self.next_db=(db)
      @next_db = db
    end

    def self.consume_next_db
      db = Model.next_db
      Model.next_db = nil
      db || BlockStack::Database.db
    end

    def self.model_for(name)
      included_classes_and_descendants.find { |c| c.dataset_name == name || c.model_name == name }
    end

    def self.included_classes
      @included_classes ||= []
    end

    def self.included_classes_and_descendants
      included_classes.flat_map { |c| [c] + c.descendants }
    end

    def self.default_config
      hash = BBLib::HashStruct.new
      hash.merge!(
        unique_by: :id, # Defines what field or fields make this object uniq. Mostly used by create_or_update to determine if a matching model exists
        paginate_at: 25, # Sets the default number of items returned for APIs
        serialize_relations: true,
        # TODO Fix caching (probably per adapter)
        cache: false, # Set to true to enable caching or false to disable it
        cache_ttl: 120 # How long a cached version of this object should live before being refreshed (seconds)
      )
      hash
    end

    # Base classes should define a type method and return a symbol or array of symbols
    # that represent what type of DB the adapter is for: e.g. :sqlite
    # def self.type
    #   nil
    # end

    module ClassMethods
      def inherited(subclass)
        subclass.db(Model.consume_next_db)
      end

      def _check_cache(method, request = nil)
        return unless config.cache
        Cache.retrieve(database_name, { method: method, request: request, model: self.to_s })
      end

      def _add_cache(result)
        return unless config.cache
        Cache.add(database_name, { method: result[:method], request: result[:args].first, model: self.to_s }, result[:value], config.cache_ttl)
      end

      def database_name
        @database_name ||= Database.name_for(db) || :unknown
      end

      def load_associations
        BlockStack::Associations.associations_for(dataset_name).each do |asc|
          send(asc.type, asc.to, asc: asc)
        end
        BlockStack::Associations.associations.values.each do |h|
          h.values.each do |asc|
            asc.through_model if asc.respond_to?(:through)
          end
        end
      end

      # TODO Add automatic uniq validation based on unique_by config
      def create(payload)
        new(payload).save
      end

      def create_or_update(payload)
        query = [config.unique_by].flatten.hmap do |field|
          [
            field.to_sym,
            payload[field]
          ]
        end
        if item = self.class.find(query)
          item.update(payload)
        else
          create(payload)
        end
      end

      def db(database = nil)
        return @db = database if database
        @db ||= Database.db
      end

      def model_name(name = nil)
        @model_name = name if name
        @model_name || to_s.split('::').last.method_case.to_sym
      end

      def plural_name(new_name = nil)
        @plural_name = new_name if new_name
        @plural_name || self.model_name.to_s.pluralize.to_sym
      end

      def clean_name
        model_name.to_s.gsub(/_+/, ' ').title_case
      end

      def attribute?(name)
        return nil unless name
        _attrs.include?(name)
      end

      def dataset_name(new_name = nil)
        return @dataset_name = new_name.to_sym if new_name
        @dataset_name ||= plural_name
      end

      def dataset
        db[dataset_name]
      end

      def ancestor_config
        config = Model.default_config
        ancestors.reverse.each do |a|
          next if a == self
          config = config.merge(a.config) if a.respond_to?(:config)
        end
        config
      end

      def config?(key)
        configuration.include?(key)
      end

      def config(args = nil)
        case args
        when Hash
          args.each { |k, v| configuration[k.to_sym] = v }
        when String, Symbol
          configuration.to_h.hpath(args).first
        when nil
          configuration
        else
          # Nada
        end
      end

      def instantiate(result)
        return nil unless result
        return result if result.is_a?(Model)
        if respond_to?(:custom_instantiate)
          send(:custom_instantiate, result)
        else
          self.new(result)
        end
      end

      def instantiate_all(*results)
        results.map { |r| instantiate(r) }
      end

      def validate(attribute, type, *expressions, **opts, &block)
        opts = opts.merge(expressions: expressions) unless expressions.empty?
        opts = opts.merge(expressions: block, type: :custom) if block
        self.validations << Validation.new(opts.merge(attribute: attribute, type: type))
      end

      def dform(obj = self)
        DFormed.form_for(obj, bypass: true)
      end

      # Returns the controller class for this model if one exists.
      # If the build param is set to true, a class will be dynamically
      # instantiated if one does not already exist.
      def controller(build = false, crud: false)
        raise RuntimeError, "BlockStack::Controller not found. You must require it first if you wish to use it: require 'block_stack/server'" unless defined?(BlockStack::Controller)
        return @controller if @controller
        controller_class = BlockStack.setting(:default_controller) unless controller_class.is_a?(BlockStack::Controller)
        # Figure out this classes namespace
        namespace = self.to_s.split('::')[0..-2].join('::')
        if namespace.empty?
          namespace = Object
          const_name = "#{self}Controller"
        else
          namespace = Object.const_get(namespace)
          const_name = "#{namespace}::#{self}Controller"
        end
        # Look for a controller class that matches our model in the same namespace
        if namespace.const_defined?(const_name)
          self.controller = namespace.const_get(const_name)
        elsif build
          # If a match was not found and build was set to true, we will create a new controller
          self.controller = namespace.const_set(const_name.split('::').last, Class.new(controller_class))
          controller.crud(self) if crud
        else
          return nil
        end
        @controller
      end

      def controller=(cont)
        raise RuntimeError, "BlockStack::Controller not found. You must require it first if you wish to use it: require 'block_stack/server'" unless defined?(BlockStack::Controller)
        @controller = cont
      end
    end

    module InstanceMethods
      def ==(obj)
        obj.is_a?(Model) && self.class == obj.class && id == obj.id
      end

      def exist?
        query = [config.unique_by].flatten.hmap do |field|
          [
            field.to_sym,
            attribute(field)
          ]
        end
        self.class.exist?(query)
      end

      def dataset_name
        self.class.dataset_name
      end

      def dataset
        self.class.dataset
      end

      def attributes
        self.class._attrs.keys
      end

      def attribute(name)
        send(name) if attribute?(name)
      end

      def attribute?(name)
        return nil unless name
        _attrs.include?(name) && respond_to?(name)
      end

      def associations
        BlockStack::Associations.associations_for(self)
      end

      def update(params, save_after = true)
        return false unless valid?
        params.each do |k, v|
          if attribute?(k)
            send("#{k}=", v)
          else
            warn("Unknown attribute #{k} passed to #{self.class} in update params. Ignoring it...")
          end
        end
        save_after ? save : true
      end

      def refresh
        self.class.find(id).serialize.each do |k, v|
          send("#{k}=", v) if k.respond_to?("#{k}=")
        end
        reset_change_set
        true
      end

      def save(skip_associations = false)
        return true unless change_set.changes?
        logger.debug("About to save #{clean_name} ID: #{id}")
        raise InvalidModel, self unless valid?
        self.updated_at = Time.now
        adapter_save
        save_associations unless skip_associations
        refresh
      end

      def delete
        logger.debug("Deleting #{clean_name} with ID #{id}.")
        delete_associations
      end

      def save_associations
        _attrs.find_all { |name, a| a[:options][:association] }.each do |name, opts|
          items = [send(name)].flatten(1).flat_map do |value|
            next unless value
            value.save(true) unless value.exist?
            value
          end.compact
          items = items.first if opts[:options][:association].singular?
          opts[:options][:association].associate(self, items) if items
        end
      end

      def valid?
        return true if validations.empty?
        validate
        self.errors.empty?
      end

      def errors
        validate
        errors
      end

      def validate
        self.errors.clear
        validations.each do |validation|
          valid = validation.valid?(self)
          next if valid
          (errors[validation.attribute] ||= []).push(validation.message)
        end
        self.errors = errors.hmap { |k, v| [k, v.uniq] }
      end

      def delete_associations
        debug { "Deleting associations for #{self.class.clean_name} #{id}." }
        BlockStack::Associations.associations_for(self).all? do |asc|
          debug("Deleting association for #{self.class.clean_name} #{id}: #{asc}")
          asc.delete(self)
        end
      end

      def dform
        self.class.dform(self)
      end

      protected

      def adapter_save
        # Define some logic here on each adapter
      end

      def adapter_delete
        # Define custom delete logic for each adapter
      end

      def reset_change_set
        change_set.reset
      end

      def simple_init(*args)
        reset_change_set
      end
    end

  end
end
