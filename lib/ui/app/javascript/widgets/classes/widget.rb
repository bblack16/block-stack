Document.on 'ready turbolinks:load' do
  after(1) do
    Widgets.load_widgets
  end
end

module Widgets

  class Widget
    include BBLib::Effortless
    attr_of Element, :element, pre_proc: proc { |x| x.is_a?(String) ? Element[x] : x }

    def update(content = nil)
      # Place update code here
      "Updated @ #{Time.now}"

      # You can also use a builder by calling the render method (example below)
      ####### CODE ########
      # render do
      #   div(id: 'myDiv') do
      #     h1 "Title of Div"
      #     p "Text of the div", style: { color: :red }
      #   end
      # end
    end

    protected

    def render(elem = :div, **attributes, &block)
      BBLib::HTML::Builder.build(elem, attributes.merge(context: context), &block).render
    end

    def context
      self
    end

    def refresh
      element.html(update.to_s)
    end

  end

  def self.widgets
    @widgets ||= []
  end

  def self.load_widgets
    Element['[blockstack-widget]'].each do |element|
      begin
        attributes = element.attributes.select { |k, v| k.to_s.start_with?('widget-') }.hmap { |k, v| [k.to_s.sub('widget-', ''), v] }
        widget = Widgets.const_get(element.attr('blockstack-widget')).new(attributes.merge(element: element))
        widget.start if widget.respond_to?(:start)
        widgets << widget
      rescue StandardError => e
        puts "Error loading widget...#{e}"
      end
    end
  end

end
