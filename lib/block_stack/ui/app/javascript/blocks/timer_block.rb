module Blocks
  class TimerBlock < Block
    attr_of Object, :timer
    attr_int :interval, default: 1
    attr_bool :updating, default: false

    def start
      stop
      execute_update
      self.timer = every(interval) do
        execute_update
      end
    end

    def stop
      timer.stop if timer
    end

    def restart
      stop
      start
    end

    protected

    def execute_update
      unless updating?
        updating = true
        refresh
        updating = false
      end
    end

  end
end
