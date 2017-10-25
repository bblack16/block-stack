# Basic clock Widget
module Widgets
  class Clock < TimerWidget
    attr_str :format, default: '%H:%M:%S'

    def update(c)
      Time.now.strftime(format)
    end
  end
end
