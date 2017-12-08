module BlockStack
  class RouteTemplate
    include BBLib::Effortless
    VERBS = BlockStack::VERBS.map { |v| [v, "#{v}_api".to_sym] }.flatten

    attr_sym :title, required: true, arg_at: 0
    attr_element_of VERBS, :verb, default: :get, arg_at: 1
    attr_str :route, required: true, arg_at: 2
    attr_sym :group, default: nil, allow_nil: true, arg_at: 3
    attr_hash :args
    attr_of Proc, :block, required: true, arg_at: :block
    attr_of Proc, :processor, default: nil, allow_nil: true

    setup_init_foundation(:type) do |a, b|
      [a].flatten(1).include?(b.to_sym)
    end

    def self.type
      self.to_s.split('::').last.downcase.to_sym
    end

    def add_to(server, opts = {})
      processor.call(server) if processor
      server.send(opts[:verb] || verb, opts[:route] || route, opts[:args] || args, &block)
    end
  end

  def self.route_templates
    @route_templates ||= []
  end

  def self.add_route_template(*args, &block)
    if BBLib.are_all?(RouteTemplate, *args)
      route_templates.unshift(*args)
    else
      route_templates.unshift(RouteTemplate.new(*args, &block))
    end
  end

  def self.route_template(title, group = nil)
    route_templates.find { |temp| temp.title == title.to_sym && temp.group == group&.to_sym }
  end

  def self.route_template_group(group)
    route_templates.find_all { |temp| temp.group == group.to_sym }
  end
end
