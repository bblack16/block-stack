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

    def render_block(view, engine = settings.default_renderer, **locals, &block)
      self.send(engine, "blocks/#{view}".to_sym, locals.delete(:options) || {}, locals, &block)
    end
  end
end
