require 'bblib' unless defined?(BBLib::VERSION)
require 'gyoku'
require 'json'
require 'yaml'
require 'sinatra'

require_relative 'block_stack/version'
require_relative 'constants'
require_relative 'formatter'
require_relative 'server'
require_relative 'controller'

BlockStack::Server.set(controller_base: BlockStack::Controller)
