class PollWidget < React::Component::Base
  attr_accessor :timer, :url, :updating, :content, :interval

  before_mount do
    load_defaults
    refresh_content
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
    @timer = every(self.interval) do
      refresh_content
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
    div { 'Someone really should have overriden this...' }
  end

  protected

  def refresh_content
    return if updating?
    self.updating = true
    HTTP.get(url) do |response|
      if response.ok?
        self.updating = false
        self.content = response.json
        force_update!
      end
    end
  end
end
