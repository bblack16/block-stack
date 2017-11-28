require_relative 'patches/server'

BlockStack.logger.info('Loaded BlockStack auth plugin.')
BlockStack.settings.authentication = true
