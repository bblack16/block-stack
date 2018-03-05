module BlockStack
  # General helpers for the UI BlockStack server
  module GeneralHelper
    def menu
      self.class.menu
    end

    def title
      self.class.title
    end

    def redirect(uri, *args)
      named = BBLib.named_args(*args)
      if named[:notice]
        session[:notice] = named[:notice]
        session[:severity] = named[:severity] || :info
      end
      super
    end

    def squish(string, *args)
      chopped = BBLib.chars_up_to(string, *args)
      return chopped if chopped == string
      BBLib::HTML::Tag.new(:span, content: chopped, attributes: { title: string })
    end

    def render_block(view, model = nil, **locals, &block)
      Block.new(type: view).render(self, model, locals, &block)
    end

    def display_value(value, label = nil)
      case value
      when Array
        if value.all? { |v| v.is_a?(String) && v.size <= 128 }
          value.join_terms
        elsif value.any? { |v| v.is_a?(Hash) }
          value.map { |v| display_value(v) }.join('<hr>')
        elsif value.empty?
          BBLib::HTML::Tag.new(:i, 'Empty', style: 'color: #bebdbd')
        else
          '<ul>' + value.map { |v| "<li>#{v}</li>" }.join + '</ul>'
        end
      when Time
        value.strftime(config.time_format)
      when Date
        value.strftime(config.date_format)
      when Float, Integer
        label.nil? || label =~ /[^\_\-\.](id|year|time)[$\s\_\-\.]/i ? value : value.to_delimited_s
      when Hash
        '<ul style="list-style-type: none">' + value.flat_map do |k, v|
          "<li><b>#{k}</b>:&nbsp;#{display_value(v)}</li>"
        end.join + '</ul>'
      when Regexp
        value.inspect
      when String
        if value =~ /^https?\:\/{2}|^w{3}\.|^\/[\w\d]|^\/$/i
          BBLib::HTML::Tag.new(:a, value, href: value)
        else
          value.to_s
        end
      when NilClass
        BBLib::HTML::Tag.new(:i, 'nil', style: 'color: #bebdbd')
      else
        value.to_s
      end
    end
  end
end
