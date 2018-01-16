module BlockStack
  module Authentication
    class Source
      include BBLib::Effortless

      attr_str :name, default_proc: proc { |x| x.to_s }

      # This method should be overriden in subclasses. This class should return
      # an array containing an id (username) and a secret (password) if found or
      # nil or false if no valid credentials can be extracted.
      # These credentials will then be passed to various auth providers.
      def credentials(request, params)
        # Example return => ['bblack', 'myS5cur3P@ss!']
        false
      end

      def credentials?(*args)
        extract(*args) ? true : false
      end
    end
  end

  load_all(File.expand_path('../sources', __FILE__))
end
