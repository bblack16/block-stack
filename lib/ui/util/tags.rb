module BlockStack
  # Tag (HTML) related methods. Exposed to UI Server and mapped
  # directly to blockstack for access to any class.
  module TagHelper
    def tag(type, content = nil, attributes = {}, &block)
      # attr_str = attributes.map { |k, v| "#{k}=\"#{v.to_s.gsub('"', '\\"')}\"" }.join(' ')
      # attr_str = ' ' + attr_str unless attr_str.empty?
      BBLib::HTML::Tag.new(type, content: content, attributes: attributes, &block)
      # puts tag.to_str, "<#{type}#{attr_str}>#{content}</#{type}>", '-' * 30
      # "<#{type}#{attr_str}>#{content}</#{type}>"
    end

    def link_to(url, text, label = {}, attributes = {})
      if label.is_a?(Hash)
        attributes = label
        label = nil
      end
      if text.is_a?(Model)
        case url
        when :edit, :update
          tag(:a, (label || 'Edit'), attributes.merge(href: "/#{text.class.dataset_name}/#{text.id}/edit"))
        when :delete, :destroy
          tag(:a, (label || 'Delete'), attributes.merge(class: ('delete-model-btn ' + attributes[:class].to_s).strip, href: '#', 'del-url': "/api/#{text.class.dataset_name}/#{text.id}", 're-url': "/#{text.class.dataset_name}"))
        when :index
          tag(:a, (label || 'Index'), attributes.merge(href: "/#{text.class.dataset_name}"))
        when :show, :view
          tag(:a, (label || 'View'), attributes.merge(href: "/#{text.class.dataset_name}/#{text.id}"))
        else
          tag(:a, (label || url.to_s.title_case), attributes.merge(href: "/#{text.class.dataset_name}/#{text.id}/#{url}"))
        end
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
        tag(:script, '', type: type, src: "#{asset_prefix + 'javascript/' + path}" )
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
