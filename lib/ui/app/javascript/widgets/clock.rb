# Basic clock Widget
module Widgets
  class Clock < TimeWidget
    attr_reader :format

    def load_defaults
      self.interval = 1
    end

    def format
      @format ||= '%H:%M:%S'
    end

    def format=(str)
      @format = str.to_s
    end

    def render
      Time.now.strftime(format)
    end
  end
end
