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

    def render_block(view, locals = {}, &block)
      Block.new(type: view).render(self, locals, &block)
    end

    def display_value(value, label = nil)
      case value
      when Array
        value.join_terms
      when Time
        value.strftime(config.time_format)
      when Date
        value.strftime(config.date_format)
      when Float, Integer
        label.nil? || label =~ /[^\_\-\.]id[$\s\_\-\.]/i ? value : value.to_delimited_s
      else
        value.to_s
      end
    end
  end
end
