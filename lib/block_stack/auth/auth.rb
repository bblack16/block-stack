require_relative 'encryption/encryption'
require_relative 'login/login'

require_relative 'helpers/basic_auth'
require_relative 'helpers/user_auth'

require_relative 'authentication/exception'
require_relative 'authentication/exception'
require_relative 'authentication/source'
require_relative 'authentication/provider'

require_relative 'authorization/match'
require_relative 'authorization/base'
require_relative 'authorization/route'
require_relative 'patches/server'
require_relative 'patches/controller'
require_relative 'patches/menu_item'

BlockStack.logger.info('Loaded BlockStack auth plugin.')
BlockStack.settings.authentication = true
BlockStack.load_all(File.expand_path('../templates', __FILE__))
