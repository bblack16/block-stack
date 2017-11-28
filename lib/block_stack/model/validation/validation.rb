module BlockStack
  class Validation
    include BBLib::Effortless

    TYPES = [
      :exists, :not_empty, :empty, :eq, :gt, :gte, :lt,
      :lte, :in, :contains, :start_with, :end_with, :matches,
      :length, :uniq, :custom
    ]

    MODES = [:any, :all, :none]

    attr_sym :attribute, required: true, arg_at: 0
    attr_element_of TYPES, :type, required: true
    attr_element_of MODES, :mode, default: MODES.first
    attr_ary :expressions, default: []
    attr_bool :inverse, default: false
    attr_str :message, default: 'Invalid value'

    alias expression expressions

    def valid?(model)
      value = model.attribute(attribute)
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

    def uniq(value, exp, model)
      !model.class.distinct(attribute).include?(value)
    end

    def custom(value, exp)
      return false unless exp.is_a?(Proc)
      exp.call(value)
    end

  end
end
