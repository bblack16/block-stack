require 'json'
require 'yaml'
require 'gyoku'
require 'bblib' unless defined?(BBLib::VERSION)
require 'sinatra/base'

require_relative 'block_stack/version'
require_relative 'block_stack/constants'
require_relative 'block_stack/formatters/formatter'
require_relative 'block_stack/server/server'
require_relative 'block_stack/controller/controller'

# TODO Decide if the default should load all controllers (probably not)
# BlockStack::Server.set(controller_base: BlockStack::Controller)
