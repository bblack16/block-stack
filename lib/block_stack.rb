require 'json'
require 'yaml'
require 'gyoku'
require 'bblib' unless defined?(BBLib::VERSION)
require 'sinatra/base'

require_relative 'block_stack/version'
require_relative 'constants'
require_relative 'formatters/formatter'
require_relative 'server/server'
require_relative 'controller/controller'

# TODO Decide if the default should load all controllers (probably not)
# BlockStack::Server.set(controller_base: BlockStack::Controller)
