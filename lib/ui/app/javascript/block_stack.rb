class Element
  alias_native :attrs

  def attributes
    Hash.new(attrs)
  end
end

require 'javascript/block_stack/alert'
require 'javascript/block_stack/loaders'
require 'javascript/block_stack/dformed'


Document.on 'ready turbolinks:load' do
  # Load params into a constant
  PARAMS = JSON.parse(Element['#params'].attr('json'))
  Element['#params'].remove

  Loaders.load_all
end

module BlockStack
  def self.redirect(url, delay = 0)
    after(delay) { `window.location.href = #{url}` }
  end
end
