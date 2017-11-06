class Element
  alias_native :attrs

  def attributes
    Hash.new(attrs)
  end
end

require 'javascript/block_stack/alert'
require 'javascript/block_stack/loaders'
require 'javascript/block_stack/dformed'
require 'javascript/blocks/block'

Document.on 'turbolinks:load' do
  Loaders.load_all
end

Document.ready? do
  Loaders.load_all
end

module BlockStack
  def self.redirect(url, delay = 0)
    after(delay) { `window.location.href = #{url}` }
  end
end
