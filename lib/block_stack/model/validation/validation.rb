module BlockStack
  class Validation
    include BBLib::Effortless

    TYPES = [
      :exists, :not_empty, :empty, :eq, :gt, :gte, :lt,
      :lte, :in, :contains, :start_with, :end_with, :matches,
      :length, :uniq, :uniq_or_nil, :custom, :custom_model
    ]

    MODES = [:any, :all, :none]

    attr_sym :attribute, required: true, arg_at: 0
    attr_element_of TYPES, :type, required: true
    attr_element_of MODES, :mode, default: MODES.first
    attr_ary :expressions, default: [], arg_at: :block
    attr_bool :inverse, default: false
    attr_str :message, default: ''
    attr_bool :allow_nil, default: false

    after :type=, :apply_default_message

    alias expression expressions

    def valid?(model)
      @model = model
      value = model.attribute(attribute)
      return true if value.nil? && allow_nil?
      mode_method = (mode == :none ? :any : mode)
      if expressions.empty?
        valid = send(type, value, nil)
      else
        valid = expressions.send("#{mode_method}?") do |exp|
          send(type, value, exp)
        end
      end
      inverse? ? !valid : valid
    end

    def exists(value, exp)
      !value.nil?
    end

    def not_empty(value, exp)
      !empty(value, exp)
    end

    def empty(value, exp)
      value.nil? || value.respond_to?(:empty?) && value.empty?
    end

    def eq(value, exp)
      exp == value
    end

    def gt(value, exp)
      BBLib.is_a?(value, Integer, Float) && value > exp
    end

    def gte(value, exp)
      BBLib.is_a?(value, Integer, Float) && value >= exp
    end

    def lt(value, exp)
      BBLib.is_a?(value, Integer, Float) && value < exp
    end

    def lte(value, exp)
      BBLib.is_a?(value, Integer, Float) && value <= exp
    end

    def in(value, exp)
      exp.is_a?(Array) ? exp.include?(value) : eq(value, exp)
    end

    def contains(value, exp)
      value.to_s.include?(exp.to_s)
    end

    def start_with(value, exp)
      value.to_s.start_with?(exp.to_s)
    end

    def end_with(value, exp)
      value.to_s.end_with?(exp.to_s)
    end

    def matches(value, exp)
      return false unless exp.is_a?(Regexp)
      value.to_s =~ exp
    end

    def uniq(value, exp)
      if @model.exist?
        !@model.class.find_all(attribute => value).any? do |match|
          match != @model
        end
      else
        !@model.class.distinct(attribute).include?(value)
      end
    end

    def custom(value, exp)
      return false unless exp.is_a?(Proc)
      exp.call(value)
    end

    def custom_model(value, exp)
      return false unless exp.is_a?(Proc)
      exp.call(@model)
    end

    protected

    def apply_default_message
      return unless message.empty?
      self.message =  attribute.to_s.gsub('_', '').title_case +
        case type
        when :exists
          " must#{inverse? ? ' not' : nil} exist."
        when :not_empty
          " must#{inverse? ? nil : ' not'} be empty."
        when :empty
          " must#{inverse? ? ' not' : nil} be empty."
        when :eq
          " must#{inverse? ? ' not' : nil} be equal to #{expressions.join_terms(mode == :all ? :and : :or)}."
        when :gt
          " must#{inverse? ? ' not' : nil} be greater than #{expressions.join_terms(mode == :all ? :and : :or)}."
        when :gte
          " must#{inverse? ? ' not' : nil} be greater than or equal to #{expressions.join_terms(mode == :all ? :and : :or)}."
        when :lt
          " must#{inverse? ? ' not' : nil} be less than #{expressions.join_terms(mode == :all ? :and : :or)}."
        when :lte
          " must#{inverse? ? ' not' : nil} be less than or equal to #{expressions.join_terms(mode == :all ? :and : :or)}."
        when :in
          " must#{inverse? ? ' not' : nil} be in #{expressions.join_terms(mode == :all ? :and : :or)}."
        when :contains
          " must#{inverse? ? ' not' : nil} be contained in #{expressions.join_terms(mode == :all ? :and : :or)}."
        when :start_with
          " must#{inverse? ? ' not' : nil} start with #{expressions.join_terms(mode == :all ? :and : :or)}."
        when :end_with
          " must#{inverse? ? ' not' : nil} end with #{expressions.join_terms(mode == :all ? :and : :or)}."
        when :matches
          " must#{inverse? ? ' not' : nil} match #{expressions.join_terms(mode == :all ? :and : :or)}."
        when :uniq
          " must#{inverse? ? ' not' : nil} be unique."
        when :uniq_or_nil
          " must#{inverse? ? ' not' : nil} be unique or null."
        else
          " is not valid."
        end
    end

  end
end
