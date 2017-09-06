module BlockStack
  module Associations
    ASSOCIATION_TYPES = [:one_to_one, :one_to_many, :many_to_one, :many_to_many, :one_through_one]

    def self.associations
      @associations ||= {}
    end

    def self.types
      BlockStack::Association.descendants.flat_map { |d| d.type }.uniq
    end

    def self.add(asc, add_opposite = true)
      (associations[asc.from] ||= {})[asc.method_name] = asc
      add(asc.opposite, false) if add_opposite && !association?(asc.to, asc.from)
      asc
    end

    def self.association?(model, dataset)
      associations[model] && associations[model][dataset] ? true : false
    end

    def self.retrieve(from, to)
      association_for(from, to)&.retrieve(from)
    end

    def self.association_for(from, method)
      from = from.dataset_name if from.is_a?(Model)
      # to = to.dataset_name if to.is_a?(Model)
      associations[from] ? associations[from][method] : nil
    end

    def self.associations_for(obj)
      dataset_name = obj.is_a?(Model) ? obj.dataset_name : obj
      associations[dataset_name]&.values || []
    end

    def self.register(*args)
    end

    def self.for?(*args)
    end

    # def self.register(dataset, type, method, opts = {}, register_associations = true)
    #   raise ArgumentError, "Unknown association type #{type}." unless ASSOCIATION_TYPES.include?(type)
    #   return if for?(dataset, method) && register_associations == false
    #   asc         = associations[dataset] ||= {}
    #   asc_dataset = opts[:model] || method
    #   attribute   = opts[:attribute] || (opts[:fkey] || type == :many_to_one || type != :many_to_many && type != :one_through_one ? "#{asc_dataset.singularize}_id".to_sym : :id)
    #   column      = opts[:column] || (opts[:fkey] || type == :many_to_one || type == :many_to_many || type == :one_through_one ? :id : "#{dataset.singularize}_id".to_sym)
    #   asc[method] = opts.merge(type: type, model: nil, asc_dataset: asc_dataset, attribute: attribute, column: column)
    #   if register_associations
    #     case type
    #     when :one_to_one
    #       attribute   = opts[:attribute] || (opts[:fkey] ? "#{asc_dataset.singularize}_id".to_sym : :id)
    #       column      = opts[:column] || (opts[:fkey] ? :id : "#{dataset.singularize}_id".to_sym)
    #       register(asc_dataset.pluralize, type, dataset.singularize, { attribute: column, column: attribute, fkey: (opts[:fkey] ? false : true) }, false)
    #     when :one_to_many
    #       attribute   = opts[:attribute] || :id
    #       column      = opts[:column] || "#{dataset.singularize}_id".to_sym
    #       register(asc_dataset, :many_to_one, dataset.singularize, { attribute: column, column: attribute }, false)
    #     when :many_to_one
    #       attribute   = opts[:attribute] || "#{asc_dataset.singularize}_id".to_sym
    #       column      = opts[:column] || :id
    #       register(asc_dataset.pluralize, :one_to_many, dataset, { attribute: column, column: attribute }, false)
    #     when :many_to_many
    #       register(opts[:through], :one_to_one, dataset.singularize, { attribute: "#{dataset}_id", column: attribute })
    #       register(opts[:through], :one_to_one, asc_dataset.singularize, { attribute: "#{asc_dataset}_id".to_sym, column: attribute })
    #       attribute   = opts[:attribute] || :id
    #       column      = opts[:column] || :id
    #       register(asc_dataset, type, dataset, { attribute: attribute, column: column, through: opts[:through] }, false)
    #     when :one_through_one
    #       register(opts[:through], :one_to_one, dataset.singularize, { attribute: "#{dataset}_id", column: attribute })
    #       register(opts[:through], :one_to_one, asc_dataset.singularize, { attribute: "#{asc_dataset}_id".to_sym, column: attribute })
    #       attribute   = opts[:attribute] || :id
    #       column      = opts[:column] || :id
    #       register(asc_dataset.pluralize, type, dataset.singularize, { attribute: attribute, column: column, through: opts[:through] }, false)
    #     end
    #   end
    # end
    #
    # def self.associations_for(klass)
    #   asc = associations[klass.is_a?(Symbol) ? klass : klass.dataset_name]
    # end
    #
    # def self.for?(obj, method)
    #   asc = associations_for(obj)
    #   asc && asc[method] ? true : false
    # end
    #
    # def self.for(obj, method)
    #   asc = associations_for(obj)
    #   return asc unless method && asc
    #   details = asc[method]
    #   model = (details[:model] ||= BlockStack::Model.model_for(details[:asc_dataset]))
    #   case details[:type]
    #   when :one_to_one, :many_to_one
    #     model.first(details[:column] => obj.attribute(details[:attribute]))
    #   when :one_to_many
    #     model.find_all(details[:column] => obj.attribute(details[:attribute]))
    #   when :many_to_many, :one_through_one
    #     through_model     = (details[:through_model] ||= BlockStack::Model.model_for(details[:through]))
    #     through_column    = (details[:through_column] ||= "#{obj.class.model_name}_id".to_sym ||= "#{model.model_name}_id".to_sym)
    #     through_attribute = (details[:through_attribute] ||= "#{model.model_name}_id".to_sym)
    #     if details[:type] == :many_to_many
    #       join_ids = through_model.find_all(through_column => obj.attribute(details[:attribute])).map { |r| r.attribute(through_attribute) }.uniq
    #       return [] unless join_ids && !join_ids.empty?
    #       model.find_all(details[:column] => join_ids)
    #     else
    #       attrib = through_model.first(through_column => obj.attribute(details[:attribute]))&.attribute(through_attribute)
    #       return nil unless attrib
    #       model.first(details[:column] => attrib)
    #     end
    #   end
    # rescue => e
    #   obj.error(e) rescue BlockStack.logger.error(e)
    #   if details && details[:type]
    #     case details[:type]
    #     when :one_to_one, :many_to_one, :one_through_one
    #       nil
    #     else
    #       []
    #     end
    #   else
    #     raise ArgumentError, "Unknown association from #{obj} with method :#{method}"
    #   end
    # end
    #
    # def self.associate(obj, method, *associations)
    #   asc = associations_for(obj)
    #   details = asc[method]
    #   return nil unless details && asc
    #   case details[:type]
    #   when :one_to_one
    #     association = associations.first
    #     association = (details[:model] ||= BlockStack::Model.model_for(method)).find(association) unless association.is_a?(Model)
    #     asc_one_to_one(details, obj, association)
    #   when :one_to_many
    #     associations = associations.map do |a|
    #       a.is_a?(Model) ? a : (details[:model] ||= BlockStack::Model.model_for(method)).find(a)
    #     end
    #     asc_one_to_many(details, obj, *associations)
    #   when :many_to_one
    #     association = associations.first
    #     association = (details[:model] ||= BlockStack::Model.model_for(method)).find(association) unless association.is_a?(Model)
    #     asc_many_to_one(details, obj, association)
    #   when :many_to_many
    #     associations = associations.map do |a|
    #       a.is_a?(Model) ? a : (details[:model] ||= BlockStack::Model.model_for(method)).find(a)
    #     end
    #     asc_many_to_many(details, obj, *associations)
    #   when :one_through_one
    #     association = associations.first
    #     association = (details[:model] ||= BlockStack::Model.model_for(method)).find(association) unless association.is_a?(Model)
    #     asc_one_through_one(details, obj, association)
    #   end
    # end
    #
    # def self.asc_one_to_one(details, obj_a, obj_b)
    #   if details[:fkey]
    #     query = { details[:attribute] => obj_b.attribute(details[:column]) }
    #     obj_a.class.find_all(query).each { |i| i.update(details[:attribute] => nil) }
    #     obj_a.update(query)
    #   else
    #     query = { details[:column] => obj_a.attribute(details[:attribute]) }
    #     obj_b.class.find_all(query).each { |i| i.update(details[:column] => nil) }
    #     obj_b.update(query)
    #   end
    # end
    #
    # def self.asc_one_to_many(details, obj, *others)
    #   query = { details[:column] => obj.attribute(details[:attribute]) }
    #   others.each { |a| a.class.find_all(query).each { |i| i.update(details[:column] => nil) } }
    #   others.each { |a| a.update(query) }
    # end
    #
    # def self.asc_many_to_one(details, obj_a, obj_b)
    #   query = { details[:attribute] => obj_b.attribute(details[:column]) }
    #   obj_a.update(query)
    # end
    #
    # def self.asc_many_to_many(details, obj, *others)
    #   through_model     = (details[:through_model] ||= BlockStack::Model.model_for(details[:through]))
    #   through_column    = (details[:through_column] ||= "#{obj.class.model_name}_id".to_sym ||= "#{model.model_name}_id".to_sym)
    #   through_attribute = (details[:through_attribute] ||= "#{others.first.class.model_name}_id".to_sym)
    #   query = { through_column => obj.attribute(details[:attribute]) }
    #
    #   through_model.find_all(query).each { |t| t.delete }
    #   through_model.create(*others.map { |o| { through_attribute => o.attribute(details[:column]), through_column => obj.attribute(details[:attribute]) } })
    # end
    #
    # def self.asc_one_through_one(details, obj_a, obj_b)
    #   through_model     = (details[:through_model] ||= BlockStack::Model.model_for(details[:through]))
    #   through_column    = (details[:through_column] ||= "#{obj_a.class.model_name}_id".to_sym ||= "#{model.model_name}_id".to_sym)
    #   through_attribute = (details[:through_attribute] ||= "#{obj_b.class.model_name}_id".to_sym)
    #   query = { through_column => obj_a.attribute(details[:attribute]) }
    #   query_b = { through_attribute => obj_b.attribute(details[:column]) }
    #
    #   p query, query_b
    #   through_model.find_all(query).each { |t| t.delete }
    #   through_model.find_all(query_b).each { |t| t.delete }
    #
    #   through_model.find_all(query).each { |t| t.delete }
    #   through_model.create(through_attribute => obj_b.attribute(details[:column]), through_column => obj_a.attribute(details[:attribute]))
    # end
  end
end
