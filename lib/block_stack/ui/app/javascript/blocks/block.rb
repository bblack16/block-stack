Document.on 'turbolinks:load' do
  after(1) do
    Blocks.load_blocks
  end
end

Document.ready? do
  Blocks.load_blocks
end

module Blocks

  class Block
    include BBLib::Effortless
    attr_of Element, :element, pre_proc: proc { |x| x.is_a?(String) ? Element[x] : x }
    attr_bool :full_refresh, default: true

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

    # This method checks a BBLib::HTML::Tag against an actual DOM Element and
    # makes only the necessary changes based on recursive differences to the DOM
    # Element.
    def self.update_element(tag, element)
      element = Element[element].first if element.is_a?(String)

      # If tag is text we can't do a good comparison so we replace the whole thing
      return element.html(tag) unless tag.is_a?(BBLib::HTML::Tag)

      if tag.children.empty? # If the tag has no children we check the contents
        # If the two are equal we return true and exit
        return true if tag.to_s == element.to_s

        # Check to see if the tag and the element have the same node type
        if tag.type == element.tag_name.downcase
          # Run through the tags attributes to see what doesn't match
          tag.attributes.each do |name, value|
            next if element.attr(name).to_s == value.to_s
            element.attr(name, value)
          end
          # Check if the nodes contens match
          if element.text != tag.content
            element.html(tag.content)
          end
        else # If the node types are different we replace the element with the tag
          element.replace_with(Element[tag.to_s])
        end
      elsif element.children.empty? # If the element is empty, we simply replace it
        element.replace_with(Element[tag.to_s])
      else # If both the tag and element have children we recursively compare them
        tag.children.each_with_index do |child, x|
          if element_child = element.children.to_a[x] # If the child by element exists
            update_element(child, element_child)
          elsif element.children.empty? # If the element has no children (should be covered above, this is duplicated?)
            element.append(child.to_s)
          elsif element.children.size > x # If the element does not have enough children to have this child.
            element.find("nth-child(#{x})").after(child.to_s)
          end
        end
      end
    end

    protected

    def render(elem = :div, **attributes, &block)
      BBLib::HTML::Builder.build(elem, attributes.merge(context: context), &block)
    end

    def context
      self
    end

    def refresh
      tag = update
      if tag.is_a?(String) && !tag.strip.encap_by?('<')
        element.html(tag)
      elsif full_refresh?
        old_element = element
        self.element = Element[tag.to_s]
        old_element.replace_with(element)
      else
        update_element(tag, element)
      end
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
