require_relative 'tags'
require_relative 'images'
require_relative 'models'

module BlockStack
  # General helpers for the UI BlockStack server
  module UiHelpers
    include TagHelper
    include ImageHelper
    include ModelHelper

    def asset_prefix
      '/assets/'
    end

    def redirect(uri, *args)
      named = BBLib.named_args(*args)
      if named[:notice]
        session[:notice] = named[:notice]
        session[:severity] = named[:severity] || :info
      end
      super
    end

    def loading_messages
      @loading_messages ||= [
        'The hamster has been placed on the wheel...',
        'One sec... Let me go load that for you!',
        'Turning knobs and pressing buttons...',
        'Hold on... Flipping bits...',
        'Good things come to those who wait.',
        'Something cool is coming!',
        'Loading...',
        'Applying polish.',
        'Some seriously awesome stuff is coming.',
        'Be right there.',
        'Hold up, let me go get something to put here...',
        'Oh no, I\'m a bit bare, let me get something to cover this up',
        'On my way!'
      ]
    end

    def load_message
      loading_messages.sample
    end

    def build_menu
      self.class.menu
    end
  end
end
