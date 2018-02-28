require_relative 'model_associations'
require_relative 'validation/validation'
require_relative 'exceptions/invalid_model'
require_relative 'exceptions/uniqueness_error'
require_relative 'exceptions/invalid_association'
require_relative 'changeset'
require_relative 'configuration'
# require_relative 'query/query'

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
      base.send(:attr_int, :id, default: nil, allow_nil: true, sql_type: :primary_key, dformed: false, searchable: true)
      base.send(:attr_time, :created_at, :updated_at, default_proc: proc { Time.now }, dformed: false, blockstack: { display: false })
      base.send(:attr_of, Configuration, :configuration, default_proc: proc { |x| x.ancestor_config }, singleton: true)
      base.send(:attr_of, ChangeSet, :change_set, default_proc: proc { |x| ChangeSet.new(x) }, serialize: false, dformed: false)
      base.send(:attr_ary_of, Validation, :validations, default: [], singleton: true)
      base.send(:attr_hash, :errors, default: {}, serialize: false, dformed: false)
      base.send(:bridge_method, :config, :db, :model_name, :clean_name, :plural_name, :dataset_name, :validations, :associations)
      base.send(:config, display_name: base.clean_name)

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
          case id
          when Range
            all[id]
          else
            find(id)
          end
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

        # Returns a range of the model based on a page number. The page number uses
        # the models paginate_at to calculate the range to return.
        # If pagination is disabled, only index = 1 will return results and will
        # simply call :all.
        def page(index = 1)
          index = index.to_i
          return [] unless index.positive?
          return index == 1 ? all : [] unless config.paginate_at
          offset = (index - 1) * config.paginate_at
          cap = offset + config.paginate_at
          self[offset...cap]
        end unless respond_to?(:page)
      end
    end

    def self.Dynamic(db = Database.db)
      db = Database.databases[db.to_sym] if db.is_a?(Symbol) || db.is_a?(String)
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
      Configuration.new
    end

    module ClassMethods
      def inherited(subclass)
        subclass.db(Model.consume_next_db)
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

      def create(payload)
        new(payload).save
      end

      def create_or_update(payload)
        query = [config.unique_by].flatten.hmap do |field|
          [ field.to_sym, payload[field] ]
        end
        if item = find(query)
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

      def associations
        BlockStack::Associations.associations_for(self)
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
          args.each { |k, v| configuration.send("#{k}=", v) }
        when String, Symbol
          configuration.to_h.hpath(args).first
        when nil
          configuration
        else
          raise ArgumentError, "Not sure what to do with the argument passed to configs. Class was #{args.class}."
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
        DFormed.form_for(obj, bypass: true).tap do |form|
          associations.each { |association| association.process_dform(form, obj) if association.process_dforms? }
        end
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

      def register_link(name, tag)
        config(links: {}) unless config.links.is_a?(Hash)
        tag = BBLib::HTML.build(:a, name.to_s.title_case, href: tag) if tag.is_a?(String) && !tag.strip.encap_By?('<')
        config.links[name.to_sym] = tag
      end

      def link_for(name, label = nil, **attributes)
        if config.links && link = config.links[name.to_sym].dup
          context = attributes.delete(:context) || self
          link.content = BBLib.pattern_render(label || link.content, context)
          link.attributes = link.attributes.hmap do |k, v|
            [k, BBLib.pattern_render(v.to_s, context)]
          end
          return link.merge(attributes)
        end
      end

      def link_for?(name, context = self)
        config.links && config.links.include?(name.to_sym)
      end
    end

    module InstanceMethods
      def ==(obj)
        obj.is_a?(Model) && self.class == obj.class && id == obj.id
      end

      def exist?
        self.class.exist?(unique_by_query)
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

      def update(params, save_after = true)
        # Is the below needed?
        # raise InvalidModelError, self unless valid?
        params.each do |k, v|
          if attribute?(k)
            send("#{k}=", v)
          else
            # TODO toggle behavior (probably between warn or raise error)
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
        logger.debug("About to save #{clean_name} ID: #{id}")
        raise InvalidModelError, self unless valid?
        if exist_not_equal?
          if config.merge_if_exist
            self.id = _remote_id
          else
            raise UniquenessError, "Another #{clean_name} already exists with the same attributes (#{[config.unique_by].flatten.join_terms})"
          end
        end
        return true unless change_set.changes?
        self.updated_at = Time.now
        adapter_save
        save_associations unless skip_associations
        refresh
      end

      def delete
        logger.debug("Deleting #{clean_name} with ID #{id}.")
        delete_associations
        adapter_delete
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
        logger.debug { "Deleting associations for #{self.class.clean_name} #{id}." }
        BlockStack::Associations.associations_for(self).all? do |asc|
          logger.debug("Deleting association for #{self.class.clean_name} #{id}: #{asc}")
          asc.delete(self)
        end
      end

      def dform
        self.class.dform(self)
      end

      # Checks to see if this model exists based on it's unique_by config setting
      # and that the existing entry in the database matches this objects
      # id (or whatever a subclass considers to be ==).
      # true means a matching record by uniqueness was found, but with a different
      # id. Note, this can happen if the object itself has a nil id.
      def exist_not_equal?
        query = unique_by_query(self.serialize)
        item = self.class.find(query)
        return false unless item
        item != self
      end

      # Takes a hash of parameters and constructs a query to check existence of
      # this object in the database based on the unique_by config.
      # If no has is provided the attributes of this object are used instead.
      def unique_by_query(hash = nil)
        [config.unique_by].flatten.hmap do |field|
          [ field.to_sym, hash ? hash[field] : attribute(field) ]
        end
      end

      # Finds the ID of the first record that matches this one based on its
      # unique_by configuration. Returns nil if no match is found.
      def _remote_id
        self.class.find(unique_by_query(self.serialize))&.id
      end

      # Default methods used in default views to display this model. Can be overriden
      # in the parent class.

      def title
        [config.title_method].flatten.find { |method| return send(method) if respond_to?(method) } || "#{config.display_name} #{id}"
      end

      def description
        [config.description_method].flatten.find { |method| return send(method) if respond_to?(method) }
      end

      def tagline
        result = [config.tagline_method].flatten.find { |method| return send(method) if respond_to?(method) }
        return result if result
        result = BBLib.chars_up_to(description.to_s.split(/\.[\s$]/).first, 90)
        return result.to_s + '.' if result
        nil
      end

      def thumbnail
        [config.thumbnail_method].flatten.find { |method| return send(method) if respond_to?(method) }
        "/#{clean_name}/#{title}"
      end

      def background
        [config.background_method].flatten.find { |method| return send(method) if respond_to?(method) }
        "/#{clean_name}/background"
      end

      def icon
        [config.icon_method].flatten.find { |method| return send(method) if respond_to?(method) }
        "/#{clean_name}/icon"
      end

      def link_for(name, label = nil, **attributes)
        self.class.link_for(name, label, attributes.merge(context: self))
      end

      def link_for?(name)
        self.class.link_for?(name)
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
