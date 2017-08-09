module BlockStack
  class Model
    include BBLib::Effortless

    def self.new(*args, &block)
      named = BBLib.named_args(*args)
      if named[:_model] && named[:_model].to_s != self.to_s
        klass = descendants.find { |k| k.to_s == named[:_model] }
        p klass
        raise ArgumentError, "Unknown class type #{named[:_model]}" unless klass
        klass.new(*args, &block)
      else
        super
      end
    end

    def self.model_for(name)
      descendants.find { |d| d.to_s == name }
    end
  end
end
