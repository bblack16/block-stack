require_relative 'shared'

require 'opal'

# Check opal version. If the version is 11 or greater we need different opal-sprockets.
if Gem::Version.new(Opal::VERSION) < Gem::Version.new('0.11.0')
  OPAL_LEGACY = true
else
  OPAL_LEGACY = false
  require 'opal-sprockets'
end

require 'opal-jquery'
require 'opal-browser'
require 'sass'
require 'slim'
require 'dformed' unless defined?(DFormed::VERSION)

require_relative 'server'
require_relative 'ui/ui'
require_relative 'ui/controller/controller'
