require 'bblib' unless defined?(BBLib::VERSION)

require_relative 'block_stack/shared'
require_relative 'block_stack/model'
require_relative 'block_stack/server'
require_relative 'block_stack/ui'

# TODO Decide if the default should load all controllers (probably not)
BlockStack::Server.set(controller_base: BlockStack::Controller)
