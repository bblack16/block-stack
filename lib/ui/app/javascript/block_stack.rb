
require 'javascript/block_stack/loaders'

Document.on 'ready turbolinks:load' do
  # Load params into a constant
  PARAMS = JSON.parse(Element['#params'].attr('json'))
  Element['#params'].remove

  Loaders.load_all
end
