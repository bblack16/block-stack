module BlockStack
  class Template
    include BBLib::Effortless

    attr_sym :title, required: true, arg_at: 0
    attr_sym :group, default: nil, allow_nil: true, arg_at: 1
    attr_of Proc, :processor, default: nil, allow_nil: true, arg_at: :block

    setup_init_foundation(:type) do |a, b|
      [a].flatten(1).include?(b.to_sym)
    end

    def self.type
      self.to_s.split('::').last.downcase.to_sym
    end

    def add_to(server, opts = {})
      processor.call(server, opts) if processor
    end
  end

  def self.templates
    @templates ||= []
  end

  def self.add_template(*args, &block)
    if BBLib.are_all?(Template, *args)
      route_templates.unshift(*args)
    else
      templates.unshift(Template.new(*args, &block))
    end
  end

  def self.template(title, group = nil)
    templates.find { |temp| temp.title == title.to_sym && temp.group == group&.to_sym }
  end

  def self.template_group(group)
    templates.find_all { |temp| temp.group == group.to_sym }
  end

  load_all(File.expand_path('../types', __FILE__))
  load_all(File.expand_path('../templates', __FILE__))
end
