class TimeWidget < React::Component::Base
  attr_accessor :timer, :url, :updating, :content, :interval

  before_mount do
    load_defaults
    start
  end

  def load_defaults
    # use this to set url and custom interval
  end

  def updating?
    updating == true
  end

  def interval
    @interval ||= 1
  end

  def start
    stop
    @timer = every(interval) do
      unless updating?
        updating = true
        force_update!
        updating = false
      end
    end
  end

  def stop
    @timer.stop if @timer
  end

  def restart
    stop
    start
  end

  def render
    div { 'Someone really should have redefined this...' }
  end
end
