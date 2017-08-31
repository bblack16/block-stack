module BlockStack
  module Associations
    ASSOCIATION_TYPES = [:one_to_one, :one_to_many, :many_to_one, :many_to_many, :one_through_one]

    def self.associations
      @associations ||= {}
    end

    def self.register(dataset, type, method, opts = {}, register_associations = true)
      raise ArgumentError, "Unknown association type #{type}." unless ASSOCIATION_TYPES.include?(type)
      return if for?(dataset, method) && register_associations == false
      asc         = associations[dataset] ||= {}
      asc_dataset = opts[:model] || method
      attribute   = opts[:attribute] || (opts[:fkey] || type == :many_to_one || type != :many_to_many ? "#{asc_dataset.singularize}_id".to_sym : :id)
      column      = opts[:column] || (opts[:fkey] || type == :many_to_one || type == :many_to_many ? :id : "#{dataset.singularize}_id".to_sym)
      asc[method] = opts.merge(type: type, model: nil, asc_dataset: asc_dataset, attribute: attribute, column: column)
      if register_associations
        case type
        when :one_to_one
          attribute   = opts[:attribute] || (opts[:fkey] ? "#{asc_dataset.singularize}_id".to_sym : :id)
          column      = opts[:column] || (opts[:fkey] ? :id : "#{dataset.singularize}_id".to_sym)
          register(asc_dataset.pluralize, type, dataset.singularize, { attribute: column, column: attribute, fkey: (opts[:fkey] ? false : true) }, false)
        when :one_to_many
          attribute   = opts[:attribute] || :id
          column      = opts[:column] || "#{dataset.singularize}_id".to_sym
          register(asc_dataset, :many_to_one, dataset.singularize, { attribute: column, column: attribute }, false)
        when :many_to_one
          attribute   = opts[:attribute] || "#{asc_dataset.singularize}_id".to_sym
          column      = opts[:column] || :id
          register(asc_dataset.pluralize, :one_to_many, dataset, { attribute: column, column: attribute }, false)
        when :many_to_many, :one_through_one
          register(opts[:through], :one_to_one, dataset.singularize, { attribute: "#{dataset}_id", column: attribute })
          register(opts[:through], :one_to_one, asc_dataset.singularize, { attribute: "#{asc_dataset}_id".to_sym, column: attribute })
          attribute   = opts[:attribute] || :id
          column      = opts[:column] || :id
          register(asc_dataset, type, dataset, { attribute: attribute, column: column, through: opts[:through] }, false)
        end
      end
    end

    def self.associations_for(klass)
      asc = associations[klass.is_a?(Symbol) ? klass : klass.dataset_name]
    end

    def self.for?(obj, method)
      asc = associations_for(obj)
      asc && asc[method] ? true : false
    end

    def self.for(obj, method)
      asc = associations_for(obj)
      return asc unless method && asc
      details = asc[method]
      model = (details[:model] ||= BlockStack::Model.model_for(details[:asc_dataset]))
      case details[:type]
      when :one_to_one, :many_to_one
        model.first(details[:column] => obj.attribute(details[:attribute]))
      when :one_to_many
        model.find_all(details[:column] => obj.attribute(details[:attribute]))
      when :many_to_many, :one_through_one
        through_model     = (details[:through_model] ||= BlockStack::Model.model_for(details[:through]))
        through_column    = (details[:through_column] ||= "#{obj.class.model_name}_id".to_sym ||= "#{model.model_name}_id".to_sym)
        through_attribute = (details[:through_attribute] ||= "#{model.model_name}_id".to_sym)
        if details[:type] == :many_to_many
          join_ids = through_model.find_all(through_column => obj.attribute(details[:attribute])).map { |r| r.attribute(through_attribute) }.uniq
          model.find_all(details[:column] => join_ids)
        else
          attrib = through_model.first(through_column => obj.attribute(details[:attribute]))&.attribute(through_attribute)
          model.first(details[:column] => attrib)
        end
      end
    rescue => e
      obj.error(e) rescue BlockStack.logger.error(e)
      if details && details[:type]
        case details[:type]
        when :one_to_one, :many_to_one, :one_through_one
          nil
        else
          []
        end
      else
        raise ArgumentError, "Unknown association from #{obj} with method :#{method}"
      end
    end
  end
end
