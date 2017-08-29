module BlockStack
  module Associations
    ASSOCIATION_TYPES = [:one_to_one, :one_to_many, :many_to_one, :many_to_many, :one_through_one]

    def self.associations
      @associations ||= {}
    end

    def self.register(dataset, type, method, opts = {}, register_associations = true)
      raise ArgumentError, "Unknown association type #{type}." unless ASSOCIATION_TYPES.include?(type)
      return if for?(dataset, method) && register_associations == false
      asc                 = associations[dataset] ||= {}
      dataset_name        = (opts[:model] || method)
      plural_dataset_name = (opts[:model_plural] || dataset_name.to_s.pluralize.to_sym)
      model_name          = dataset_name.to_s.class_case
      model               = BlockStack::Model.model_for(model_name)
      attribute           = opts[:attribute] || ([:many_to_many, :one_through_one].any? { |t| t == type } ? :id : "#{dataset.to_s.singularize.to_sym}_id".to_sym)
      column              = opts[:column] || :id
      asc[method]         = opts.merge(type: type, model: model, dataset_name: dataset_name, attribute: attribute, column: column)
      if register_associations
        case type
        when :one_to_one
          register(plural_dataset_name, type, dataset.to_s.singularize.to_sym, { attribute: column, column: attribute }, false)
        when :one_to_many
          register(dataset_name, :many_to_one, dataset.to_s.singularize.to_sym, { attribute: column, column: attribute }, false)
        when :many_to_one
          register(plural_dataset_name, :one_to_many, dataset, { attribute: column, column: attribute }, false)
        when :many_to_many
          register(opts[:through], :one_to_one, dataset.to_s.singularize.to_sym, { attribute: (opts[:model] ||= BlockStack::Model.model_for(opts[:dataset_name])&.name), column: attribute }, false)
          register(opts[:through], :one_to_one, dataset_name.to_s.singularize.to_sym, { attribute: "#{(BlockStack::Model.model_for(dataset_name)&.name)}_id".to_sym, column: column }, false)
          register(dataset_name, :many_to_many, dataset, { attribute: column, column: attribute, through: opts[:through] }, false)
        when :one_through_one
          register(opts[:through], :one_to_one, dataset.to_s.singularize.to_sym, { attribute: (opts[:model] ||= BlockStack::Model.model_for(opts[:dataset_name])&.name), column: attribute }, false)
          register(opts[:through], :one_to_one, dataset_name.to_s.singularize.to_sym, { attribute: "#{dataset_name}_id".to_sym, column: column }, false)
          register(plural_dataset_name, :one_through_one, dataset.to_s.singularize.to_sym, { attribute: column, column: attribute, through: opts[:through] }, false)
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
      model = (details[:model] ||= BlockStack::Model.model_for(details[:dataset_name]))
      case details[:type]
      when :one_to_one, :many_to_one
        model.first(details[:column] => obj.attribute(details[:attribute]))
      when :one_to_many
        model.find_all(details[:attribute] => obj.attribute(details[:column]))
      when :many_to_many, :one_through_one
        through_model     = (details[:through_model] ||= BlockStack::Model.model_for(details[:through]))
        through_column    = (details[:through_column] ||= "#{model.name}_id".to_sym)
        through_attribute = (details[:through_attribute] ||= "#{obj.class.name}_id".to_sym)
        if details[:type] == :many_to_many
          join_ids          = through_model.find_all(through_attribute => obj.attribute(details[:attribute])).map { |r| r.attribute(through_column) }
          model.find_all(details[:column] => join_ids)
        else
          attrib = through_model.first(through_attribute => obj.attribute(details[:attribute]))&.attribute(through_column)
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
