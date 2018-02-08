module Blocks
  class PollBlock < TimerBlock
    attr_str :url
    attr_of Object, :content

    def update
      render(:div) do
        context.to_s
      end
    end

    protected

    def context
      content
    end

    def refresh
      refresh_content
      super
    end

    def refresh_content
      return if updating?
      self.updating = true
      HTTP.get(url) do |response|
        if response.ok?
          self.updating = false
          self.content = response.json
        end
      end
    rescue => e
      puts "Error: #{e}"
      self.updating = false
    end
  end
end
