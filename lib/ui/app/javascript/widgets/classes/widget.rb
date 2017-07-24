Document.on 'ready turbolinks:load' do
  after(1) do
    Widgets.load_widgets
  end
end

module Widgets

  def self.load_widgets
    Element['[blockstack-widget]'].each do |element|
      begin
        element.render(Widgets.const_get(element.attr('blockstack-widget')))
      rescue StandardError => e
        puts "Error loading widget...#{e}"
      end
    end
  end

end
