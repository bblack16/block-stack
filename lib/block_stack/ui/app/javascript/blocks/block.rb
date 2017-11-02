Document.on 'ready turbolinks:load' do
  after(1) do
    Blocks.load_blocks
  end
end

module Blocks

  class Block
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

  def self.blocks
    @blocks ||= []
  end

  def self.load_blocks
    Element['[blockstack-block]'].each do |element|
      begin
        attributes = element.attributes.select { |k, v| k.to_s.start_with?('block-') }.hmap { |k, v| [k.to_s.sub('block-', ''), v] }
        block = Blocks.const_get(element.attr('blockstack-block')).new(attributes.merge(element: element))
        block.start if block.respond_to?(:start)
        blocks << block
      rescue StandardError => e
        puts "Error loading block...#{e}"
      end
    end
  end

end

require 'javascript/blocks/timer_block'
require 'javascript/blocks/poll_block'
require 'javascript/blocks/clock'
