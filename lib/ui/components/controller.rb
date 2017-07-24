module BlockStack
  class Controller < BlockStack::UiServer
    # include BBLib::Effortless

    def self.descendants(include_singletons = false)
      ObjectSpace.each_object(Class).select do |c|
        (include_singletons || !c.singleton_class?) && c < self
      end
    end

  end
end
