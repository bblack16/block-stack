require_relative 'associations'

module BlockStack

  # This module is used as a contract between a class and the BlockStack
  # framework. All of the methods defined below should be implemented on the
  # model class. Some methods have default implementations, others require
  # an overriden method otherwise they raise and AbstractMethodError.
  #
  # The following methods should exist on any classes that extend this module.
  # find (or []) - Returns a single model based on an ID (or similar)
  # find_all     - Returns an array of models that match a given query.
  # all          - Returns an array of all models of this type.
  # first, last  - Returns the first or last model.
  # count        - Returns the number of data sets that exist for this model.
  # sample       - Returns a random model (optional)
  # exist?       - Returns true if this model is found in the persistence layer.
  # NOTE: At minimum, find_all and all MUST be defined in the model class.
  module Model

    def self.abstract_error
      raise AbstractError, "Method :#{caller_locations(1,1)[0].label} is abstract and should have been redefined."
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

    def self.included(base)
      included_classes.push(base)
      base.send(:include, BBLib::Effortless)
      base.extend ClassMethods

      base.singleton_class.send(:after, :all, :find_all, :instantiate_all, send_value_ary: true, modify_value: true)
      base.singleton_class.send(:after, :find, :first, :last, :sample, :instantiate, send_value: true, modify_value: true)
      base.send(:attr_int, :id, default: nil, allow_nil: true, sql_type: :primary_key, dformed_field: false)
      base.send(:attr_time, :created_at, :updated_at, default: Time.now, dformed_field: false)
      base.send(:init_type, :loose)

      unless base.respond_to?(:find)
        base.send(:define_singleton_method, :find) do |query|
          find_all(query)&.first
        end
      end

      unless base.respond_to?(:[])
        base.send(:define_singleton_method, :[]) do |id|
          case [id.class]
          when [Range]
            all[id]
          else
            find(id)
          end
        end
      end

      unless base.respond_to?(:find_all)
        base.send(:define_singleton_method, :find_all) do |query|
          BlockStack::Model.abstract_error
        end
      end

      unless base.respond_to?(:all)
        base.send(:define_singleton_method, :all) do
          BlockStack::Model.abstract_error
        end
      end

      unless base.respond_to?(:first)
        base.send(:define_singleton_method, :first) do
          all.first
        end
      end

      unless base.respond_to?(:last)
        base.send(:define_singleton_method, :last) do
          all.last
        end
      end

      unless base.respond_to?(:count)
        base.send(:define_singleton_method, :count) do
          all.size
        end
      end

      unless base.respond_to?(:sample)
        base.send(:define_singleton_method, :sample) do |query = nil|
          query ? find_all(query).sample : all.sample
        end
      end

      unless base.respond_to?(:exist?)
        base.send(:define_singleton_method, :exist?) do |query|
          query = { id: query } unless query.is_a?(Hash)
          query && find(query) != nil
        end
      end
    end

    module ClassMethods
      def model_name(name = nil)
        @model_name = name if name
        @model_name || to_s.split('::').last.method_case.to_sym
      end

      def plural_name(new_name = nil)
        @plural_name = new_name if new_name
        @plural_name || self.model_name.to_s.pluralize.to_sym
      end

      def dataset_name(new_name = nil)
        return @dataset_name = new_name.to_sym if new_name
        @dataset_name ||= plural_name
      end

      def dataset
        db[dataset_name]
      end

      def controller
        return @controller if @controller
        namespace = self.to_s.split('::')[0..-2].join('::')
        if namespace.empty?
          namespace = Object
          const_name = "#{self}Controller"
        else
          namespace = Object.const_get(namespace)
          const_name = "#{namespace}::#{self}Controller"
        end
        if namespace.const_defined?(const_name)
          @controller = namespace.const_get(const_name)
        else
          @controller = namespace.const_set(const_name, Class.new(BlockStack::PluralizedController))
        end
      end

      def controller=(cnt)
        @controller = cnt
      end

      def db(database = nil)
        return @db = database if database
        @db ||= (defined?(DB) ? DB : nil)
      end

      def instantiate(result)
        p 'OLD OLD OLD'
        return nil unless result
        return result if result.class == self
        self.new(result)
      end

      def instantiate_all(*results)
        results.map { |r| instantiate(r) }
      end

      def associations
        BlockStack::Associations.associations_for(self)
      end

      BlockStack::Associations::ASSOCIATION_TYPES.each do |type|
        define_method(type) do |method, opts = {}|
          Associations.register(dataset_name, type, method, opts)
        end
      end

      def create(*payloads)
        payloads.all? do |payload|
          new(payload).save
        end
      end

      def settings
        @settings ||= {}
      end

      def setting(key)
        settings[key]
      end

      def setting?(key)
        settings.include?(key)
      end

      def set(hash)
        hash.each { |k, v| settings[k.to_sym] = v }
      end
    end

    def settings
      self.class.settings
    end

    def setting?(key)
      self.class.setting?(key)
    end

    def setting(key)
      self.class.setting(key)
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
      send(name) if respond_to?(name)
    end

    def attribute?(name)
      respond_to?(name)
    end

    def update(params)
      params.each do |k, v|
        if attribute?(k)
          send("#{k}=", v)
        else
          warn("Unknown attribute #{k} passed to #{self.class} in update params. Ignoring it...")
        end
      end
      save
    end

    def db
      self.class.db
    end

    def save
      BlockStack::Model.abstract_error
    end

    def delete(cascade = true)
      BlockStack::Model.abstract_error
    end

    def serialize_attributes
      post_serialize(
        serialize.merge(updated_at: Time.now)
                 .merge(attribute?(:created_at) ? {} : { created_at: Time.now })
      )
    end

    def post_serialize(hash)
      hash
    end

    def exist?
      self.class.exist?(attribute(:id))
    end

    def lookup_association(method)
      Associations.for(self, method)
    end

    protected

    def method_missing(method, *args, &block)
      if Associations.for?(self, method)
        lookup_association(method)
      else
        super
      end
    end

    def respond_to_missing?(method, inc_priv = false)
      Associations.for?(self, method) || super
    end
  end
end
