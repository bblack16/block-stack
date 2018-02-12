require_relative 'shared'

require 'opal'
require 'opal-browser'
require 'opal-sprockets'
require 'opal-jquery'
require 'sass'
require 'slim'
require 'dformed' unless defined?(DFormed::VERSION)

require_relative 'server'
require_relative 'ui/ui'
require_relative 'ui/controller/controller'
