module BlockStack
  module Templates
    class Route < Template
      include BBLib::Effortless
      VERBS = BlockStack::VERBS.map { |v| [v, "#{v}_api".to_sym] }.flatten

      attr_element_of VERBS, :verb, default: :get, arg_at: 2
      attr_str :route, required: true, arg_at: 3

      setup_init_foundation(:type) do |a, b|
        [a].flatten(1).include?(b.to_sym)
      end

      def self.type
        self.to_s.split('::').last.downcase.to_sym
      end

      def add_to(server, opts = {})
        p opts[:verb] || verb, opts[:route] || route, opts
        server.send(opts[:verb] || verb, opts[:route] || route, opts[:args] || {}, &processor)
      end
    end
  end
end