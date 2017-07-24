module BlockStack
  # General helpers for the UI BlockStack server
  module UiHelpers
    def asset_prefix
      '/assets/'
    end

    def tag(type, content = nil, attributes = {})
      attr_str = attributes.map { |k, v| "#{k}=\"#{v.to_s.gsub('"', '\\"')}\"" }.join(' ')
      attr_str = ' ' + attr_str unless attr_str.empty?
      "<#{type}#{attr_str}>#{content}</#{type}>"
    end

    def link_to(text, url, attributes = {})
      tag(:a, text, attributes.merge(href: url))
    end

    def mail_to(addresses, text, attributes = {})
      mail_attrs = [:cc, :bcc, :subject, :body]
      delimiter = attributes.delete(:delimiter) || ';'
      href = "mailto:#{[addresses].flatten.join(delimiter)}?#{attributes.only(*mail_attrs).map { |k, v| "#{k}=#{v}" }.join('&')}"
      tag(:a, text, attributes.except(*mail_attrs).merge(href: href))
    end

    def javascript_include(*paths, type: 'text/javascript')
      paths.map do |path|
        tag(:script, '', type: type, src: "#{asset_prefix + 'javascript/' + path}" )
      end.join
    end

    def opal_include(*paths)
      paths.map do |path|
        javascript_include(path) + tag(:script, "Opal.modules['#{'javascript/' + path.sub(/\.js$/i, '')}'](Opal)", type:'text/javascript')
      end.join
    end

    alias opal_tag opal_include 

    def stylesheet_include(*paths)
      paths.map do |path|
        tag(:link, '', rel: 'stylesheet', href: "/assets/stylesheets/#{path}.css")
      end.join
    end

    def image_tags(*images, **opts)
      images.map do |image|
        if self.class.opal.sprockets.find_asset("images/#{image}")
          tag(:img, '', opts.except(:fallbacks, :missing).merge(src: "/assets/images/#{image}"))
        else
          fallbacks = opts[:fallbacks]
          return opts[:missing] unless fallbacks && !fallbacks.empty?
          image_tags(fallbacks.first, **opts.merge(fallbacks: fallbacks[1..-1]))
        end
      end.compact.join
    end

    alias_method :image_tag, :image_tags

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
      self.class.menu(env)
    end
  end
end
