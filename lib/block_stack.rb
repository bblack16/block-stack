require_relative "block_stack/version"

require 'yaml'
require 'json'
require 'bblib' unless defined?(BBLib::VERSION)
require 'sinatra/base'
# require 'graphql'
require 'gyoku'
require 'dformed' unless defined?(DFormed::VERSION)

require_relative 'util/util'
require_relative 'server/server'
require_relative 'formatter/formatter'
require_relative 'ui/ui'
require_relative 'ui/dformed/presets'
require_relative 'components/controller/util'
require_relative 'components/controller/controller'
require_relative 'components/controller/ui_controller'
require_relative 'components/model/model'
require_relative 'components/database'
