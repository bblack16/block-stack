# Basic clock Widget
module Blocks
  class Clock < TimerBlock
    attr_str :format, default: '%H:%M:%S'
    
    def update
      Time.now.strftime(format)
    end
  end
end
