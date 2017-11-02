module Blocks
  class TimerBlock < Block
    attr_of Object, :timer
    attr_int :interval, default: 1
    attr_bool :updating, default: false

    def start
      stop
      timer = every(interval) do
        unless updating?
          updating = true
          refresh
          updating = false
        end
      end
    end

    def stop
      timer.stop if timer
    end

    def restart
      stop
      start
    end

  end
end
