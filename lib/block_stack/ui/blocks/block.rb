# TODO Turn navbars into blocks

module BlockStack
  class Block
    include BBLib::Effortless

    attr_sym :engine, default: :slim, protected: true

    setup_init_foundation :type

    bridge_method :view, :type

    def self.type
      self.to_s.split('::').last.method_case
    end

    def self.view
      "blocks/#{type}".to_sym
    end

    def render(server, model = nil, **opts, &block)
      opts = opts.merge(model: model) if model
      server.send(engine, view, opts[:render_options] || {}, build_locals(opts), &block)
    end

    # This should be redefined in subclasses and must return a hash
    def default_locals
      {}
    end

    # This should be redefined in subclasses and must return a hash
    # with attributes to be added to the created html block
    # (such as class, id, etc...)
    def default_attributes(custom = {})
      {}
    end

    CONCAT_ATTRIBUTES = [:class, :style]

    def build_locals(custom = {})
      custom[:attributes] = attributes(custom[:attributes] || {})
      default_locals(custom).merge(custom)
    end

    # Assemble attributes
    def attributes(custom = {})
      default_attributes.merge(custom).tap do |assembled|
        CONCAT_ATTRIBUTES.each do |attr|
          value = [custom[attr], default_attributes[attr]].flatten.compact.join(' ')
          assembled[attr] = value if value && !value.empty?
        end
      end
    end
  end
end

# Load other blocks in this directory
Dir.glob(File.expand_path('..', __FILE__) + '/*.rb').each do |file|
  next if file == __FILE__
  require_relative file
end
