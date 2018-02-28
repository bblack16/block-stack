module BlockStack
  # Tag (HTML) related methods. Exposed to UI Server and mapped
  # directly to blockstack for access to any class.
  module TagHelper
    def tag(type, content = nil, attributes = {}, &block)
      BBLib::HTML::Tag.new(type, content: content, attributes: attributes, &block)
    end

    # TODO Improve the hell out of this
    def link_to(url, text = nil, label = nil, attributes = {})
      if label.is_a?(Hash)
        attributes = label
        label = nil
      end
      if text.is_a?(Model) || text.is_a?(Class) && text.ancestors.include?(Model)
        text.link_for(url, label, attributes)
      elsif url.is_a?(Model) || url.is_a?(Class) && url.ancestors.include?(Model)
        url.link_for(url, text, attributes)
      else
        tag(:a, text, attributes.merge(href: url))
      end
    end

    def mail_to(addresses, text, attributes = {})
      mail_attrs = [:cc, :bcc, :subject, :body]
      delimiter = attributes.delete(:delimiter) || ';'
      href = "mailto:#{[addresses].flatten.join(delimiter)}?#{attributes.only(*mail_attrs).map { |k, v| "#{k}=#{v}" }.join('&')}"
      tag(:a, text, attributes.except(*mail_attrs).merge(href: href))
    end

    def javascript_include(*paths, type: 'text/javascript')
      paths.map do |path|
        tag(:script, '', type: type, src: "#{config.assets_prefix + 'javascript/' + path}" )
      end.join
    end

    def opal_include(*paths)
      paths.map do |path|
        javascript_include(path) + tag(:script, "Opal.modules['#{'javascript/' + path.sub(/\.js$/i, '')}'](Opal)", type:'text/javascript')
      end.join
    end

    def stylesheet_include(*paths)
      paths.map do |path|
        tag(:link, '', rel: 'stylesheet', href: "/assets/stylesheets/#{path}.css")
      end.join
    end
  end

  extend TagHelper
end
