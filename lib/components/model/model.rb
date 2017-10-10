require_relative 'associations'
require_relative 'associations/association'
require_relative 'model_attrs'

module BlockStack

  def self.basic_search(query, models, fields)
    models.find_all do |model|
      model._attrs.any? do |name, details|
        next unless details[:options][:searchable]
        next if fields && !fields.include?(name)
        value = model.send(name)
        next unless value && !value.to_s.strip.empty?
        basic_search_match(query, value)
      end
    end
  end

  def self.basic_search_match(query, value)
    case [value.class]
    when [Array]
      value.map { |v| basic_search_match(query, v) }
    when [Hash]
      value.squish.values.map { |v| basic_search_match(query, v) }
    when [Integer], [Float]
      value == query.to_s.to_i if query =~ /^\d+$/
    when [Time]
      value == Time.parse(query) rescue nil
    when [Date]
      value == Date.parse(query) rescue nil
    else
      value =~ /#{Regexp.escape(query.to_s).gsub('\\*', '.*')}/i
    end
  end

  def self.fuzzy_matcher
    @fuzzy_matcher ||= BBLib::FuzzyMatcher.new(case_sensitive: false, convert_roman: true, remove_symbols: true, move_articles: true)
  end

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
    def self.Dynamic(db = Database.db)
      db = BlockStack::Database.databases[db.to_sym] if BBLib.is_a?(db, Symbol, String)
      Model.next_db = db
      if defined?(Mongo::Client) && db.is_a?(Mongo::Client)
        Models::Mongo
      elsif db == nil
        Models::Memory
      else
        Models::SQL
      end
    end

    def self.default_settings
      BBLib::HashStruct.new(
        primary_attribute: [:name, :title],
        description_attribute: :describe,
        detail_attribute: :details,
        tagline: :tagline,
        background: :background,
        thumbnail: :thumbnail,
        thumbnail_back: :thumbnail_back,
        icon: :icon,
        logo: :logo,
        images: [:images, :screenshots],
        # actions: {
        #
        # },
        searchable: false
      )
    end

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

    def self.included(base)
      included_classes.push(base)
      base.send(:include, BBLib::Effortless)
      base.extend ClassMethods
      base.extend ModelAttrs

      base.singleton_class.send(:after, :all, :find_all, :latest_by, :oldest_by, :search, :instantiate_all, send_value_ary: true, modify_value: true)
      base.singleton_class.send(:after, :find, :first, :last, :sample, :instantiate, send_value: true, modify_value: true)
      base.send(:after, :save, :save_associations)
      base.send(:after, :delete, :delete_associations)
      base.send(:after, :dformed_form, :add_associations_to_form, send_value: true, modify_value: true)
      base.send(:attr_int, :id, default: nil, allow_nil: true, sql_type: :primary_key, dformed: false, searchable: true)
      base.send(:attr_time, :created_at, :updated_at, default_proc: proc { Time.now }, dformed: false, blockstack: { display: false })
      base.send(:attr_of, BBLib::HashStruct, :settings, default_proc: proc { |x| x.ancestor_settings }, singleton: true)
      base.send(:init_type, :loose)
      base.send(:load_associations)

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

      # All query methods that have an arg of opts should support at minimum the following:
      # limit, offset, sort (aka order)
      unless base.respond_to?(:find_all)
        base.send(:define_singleton_method, :find_all) do |query, opts = {}|
          BlockStack::Model.abstract_error
        end
      end

      unless base.respond_to?(:all)
        base.send(:define_singleton_method, :all) do |opts = {}|
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
        base.send(:define_singleton_method, :count) do |query = {}|
          find_all(query).size
        end
      end

      unless base.respond_to?(:average)
        base.send(:define_singleton_method, :average) do |field, query = {}|
          BBLib.average(find_all(query).map{ |i| i.attribute(field) })
        end
      end

      unless base.respond_to?(:max)
        base.send(:define_singleton_method, :max) do |field, query = {}|
          find_all(query).map{ |i| i.attribute(field) }.max
        end
      end

      unless base.respond_to?(:min)
        base.send(:define_singleton_method, :min) do |field, query = {}|
          find_all(query).map{ |i| i.attribute(field) }.min
        end
      end

      unless base.respond_to?(:distinct)
        base.send(:define_singleton_method, :distinct) do |field, query = {}|
          find_all(query).map{ |i| i.attribute(field) }.uniq
        end
      end

      unless base.respond_to?(:average)
        base.send(:define_singleton_method, :average) do |field, query = {}|
          BBLib.average(find_all(query).map{ |i| i.attribute(field) })
        end
      end

      unless base.respond_to?(:sum)
        base.send(:define_singleton_method, :sum) do |field, query = {}|
          find_all(query).map{ |i| i.attribute(field) }.sum
        end
      end

      unless base.respond_to?(:latest_by)
        base.send(:define_singleton_method, :latest_by) do |field, count, query = {}|
          find_all(query).sort_by { |i| i.attribute(field) }[-(count+1)..-1]
        end
      end

      unless base.respond_to?(:oldest_by)
        base.send(:define_singleton_method, :oldest_by) do |field, count, query = {}|
          find_all(query).sort_by { |i| i.attribute(field) }[0...count]
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

      # Very basic and extremely inefficient search for base class.
      # This should be overriden in adapaters to support search for that adapter
      # The goal is for this to implement cross-field searching and partial
      # matching (such as full text search).
      unless base.respond_to?(:search)
        base.send(:define_singleton_method, :search) do |search, opts = {}|
          BlockStack.basic_search(search, all, opts[:fields])
        end
      end
    end

    module ClassMethods
      def inherited(subclass)
        subclass.db(Model.consume_next_db)
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

      def polymorphic(toggle = nil)
        unless toggle.nil?
          @polymorphic = !is_polymorphic_child? && toggle
          @polymorphic || is_polymorphic_child? ? serialize_method(:_class) : dont_serialize_method(:_class)
        end
        @polymorphic
      end

      def is_polymorphic_child?
        @polymorphic_child ||= polymorphic_model ? true : false
      end

      def polymorphic_model
        @polymorphic_model ||= ancestors.find { |a| next if a == self; a.respond_to?(:polymorphic) && a.polymorphic }
      end

      def model_name(name = nil)
        @model_name = name if name
        @model_name || to_s.split('::').last.method_case.to_sym
      end

      def plural_name(new_name = nil)
        @plural_name = new_name if new_name
        @plural_name || self.model_name.to_s.pluralize.to_sym
      end

      def dataset_name(new_name = nil)
        return polymorphic_model.dataset_name if is_polymorphic_child?
        return @dataset_name = new_name.to_sym if new_name
        @dataset_name ||= plural_name
      end

      def clean_name
        return polymorphic_model.clean_name if is_polymorphic_child?
        model_name.to_s.gsub(/_+/, ' ').title_case
      end

      def dataset
        return polymorphic_model.dataset if is_polymorphic_child?
        db[dataset_name]
      end

      def controller
        return polymorphic_model.controller if is_polymorphic_child?
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
          @controller = namespace.const_set(const_name.split('::').last, Class.new(BlockStack::UiController))
        end
      end

      def controller=(cnt)
        @controller = cnt
      end

      def build_controller
        return polymorphic_model.build_controller if is_polymorphic_child?
        controller.crud(self)
        controller
      end

      def db(database = nil)
        return polymorphic_model.db(database) if is_polymorphic_child?
        return @db = database if database
        @db ||= Database.db
      end

      def instantiate(result)
        return polymorphic_model.instantiate(result) if is_polymorphic_child?
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

      def associations
        return polymorphic_model.associations if is_polymorphic_child?
        BlockStack::Associations.associations[dataset_name] || []
      end

      def create(*payloads)
        return polymorphic_model.create(*payloads) if is_polymorphic_child?
        payloads.all? do |payload|
          new(payload).save
        end
      end

      # Current list of used settings
      # ------------------------------
      # primary_attribute [Symbol] - What is displayed as a title (method name to call)
      # description_attribute [Symbol] - The method used for a short description
      # detail_attribute [Symbol] - The method used for a larger description of the attribute
      # tagline [Symbol] - Displayed under the title in some widgets
      # background [Symbol] - The method to call to return a background image (large)
      # thumbnail [Symbol] - The method to call to return a thumbnail
      # icon [Symbol] - The method to call to return an icon
      # actions [Hash] - What actions should be made available for this model via context menus
      # searchable [Bool] - True or false to allow the model to be part of global search (Default: false)
      # table_attributes [Array of Symbols] - An array of attributes to display in tables (nil means display all serialized fields)
      def ancestor_settings
        settings = Model.default_settings
        ancestors.reverse.each do |a|
          next if a == self
          settings = settings.merge(a.settings) if a.respond_to?(:settings)
        end
        settings
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

      def image_for(type, attributes = {})
        tag = setting_call(type)
        tag.attributes = tag.attributes.merge(attributes) if tag.is_a?(BBLib::HTML::Tag)
        tag
      end

      def setting_call(name)
        return nil unless setting?(name)
        tag = send(setting(name)) if respond_to?(setting(name).to_s)
      end
    end

    def ==(obj)
      obj.is_a?(Model) && self.class == obj.class && id == obj.id
    end

    def _class
      self.class.to_s
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
      send(name) if attribute?(name)
    end

    def attribute?(name)
      return nil unless name
      _attrs.include?(name) && respond_to?(name)
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

    def refresh
      self.class.find(id).serialize.each do |k, v|
        send("#{k}=", v) if k.respond_to?("#{k}=")
      end
    end

    def db
      self.class.db
    end

    def save_associations
      _attrs.find_all { |name, a| a[:options][:association] }.each do |name, opts|
        items = [send(name)].flatten(1).flat_map do |value|
          next unless value
          value.save unless value.exist?
          value
        end.compact
        items = items.first if opts[:options][:association].singular?
        opts[:options][:association].associate(self, items) if items
      end
    end

    def delete_associations
      debug { "Deleting associations for #{self.class.clean_name} #{id}." }
      BlockStack::Associations.associations_for(self).all? do |asc|
        debug("Deleting association for #{self.class.clean_name} #{id}: #{asc}")
        asc.delete(self)
      end
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
      id && self.class.exist?(id)
    end

    def image_for(type, attributes = {})
      tag = setting_call(type)
      tag.attributes = tag.attributes.merge(attributes) if tag.is_a?(BBLib::HTML::Tag)
      tag
    end

    def describe
      setting_call(:description_attribute)
    end

    def setting_call(name)
      return nil unless setting?(name)
      tag = send(setting(name)) if respond_to?(setting(name).to_s)
    end

    def details
      if setting?(:detail_attribute)
        send(settings.detail_attribute)
      else
        serialize.hmap { |k, v| [k.to_s.gsub('_', ' ').title_case, v] }
      end
    end

    def dformed_form(form)
      DFormed.form_for(self, bypass: true)
    end

    def add_associations_to_form(form)
      self.class.associations.each do |name, asc|
        values = [send(asc.method_name)].compact.flatten(1)&.map { |m| m.id }
        next unless values
        form.field(asc.method_name)&.options = asc.dformed_options
        case [asc.class]
        when [BlockStack::Associations::OneToOne], [BlockStack::Associations::ManyToOne]
          if asc.is_a?(BlockStack::Associations::ManyToOne) || asc.foreign_key?
            form.remove(asc.method_name)
            form.replace(asc.attribute, value: values.first, label: asc.model.clean_name, name: asc.attribute, type: :select, options: asc.dformed_options)
          else
            form.field(asc.method_name)&.value = values.first
          end
        when [BlockStack::Associations::OneToMany], [BlockStack::Associations::ManyToMany]
          form.field(asc.method_name)&.value = values
        when [BlockStack::Associations::OneThroughOne]
          form.field(asc.method_name)&.value = values.first
        end
      end
      form
    end

    protected

    # def method_missing(method, *args, &block)
    #   if Associations.association?(dataset_name, method)
    #     cache_association(method)
    #     send(method)
    #   elsif method.to_s =~ /=$/ && Associations.association?(dataset_name, method.to_s[0..-2].to_sym)
    #     cache_association(method.to_s[0..-2].to_sym)
    #     send(method, *args)
    #   else
    #     super
    #   end
    # end

    def respond_to_missing?(method, inc_priv = false)
      Associations.association?(dataset_name, method) || super
    end

    def cache_association(method)
      self.class.send(:define_method, Associations.association_for(dataset_name, method).method_name) do
        BlockStack::Associations.retrieve(self, method)
      end
      self.class.send(:define_method, "#{Associations.association_for(dataset_name, method).method_name}=") do |*args|
        args.each do |arg|
          BlockStack::Associations.association_for(self, method).associate(self, arg)
        end
      end
    end
  end
end
