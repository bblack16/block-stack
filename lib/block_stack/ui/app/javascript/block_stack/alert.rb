module Alert

  def self.log(message, opts = {})
    opts = build_log_options(opts)
    message = construct_message(message, opts)
    `alertify.delay(#{opts[:delay]})
             .logPosition(#{opts[:position]})
             .maxLogItems(#{opts[:max]})
             .closeLogOnClick(#{opts[:close_on_click]})
             .custom_log(#{message}, #{opts[:type]})`
  end

  [:error, :success, :info, :warn, :debug, :purple, :white].each do |type|
    define_singleton_method(type) do |message, opts = {}|
      log(message, opts.merge(type: type))
    end
  end

  def self.alert(message, opts = {})
    `alertify.alert(#{message})`
  end

  def self.confirm(message, ack, cancel, opts= {}, &block)
    opts = build_confirm_options(opts)
    message = construct_message(message, opts)
    `alertify.okBtn(#{opts[:ok]})
             .cancelBtn(#{opts[:cancel]})
             .confirm(#{message}, #{block_given? ? block : ack})`
  end

  def self.prompt(message, ack, cancel, opts = {}, &block)
    opts = build_confirm_options(opts)
    message = construct_message(message, opts)
    `alertify.defaultValue(#{opts[:default]})
             .okBtn(#{opts[:ok]})
             .cancelBtn(#{opts[:cancel]})
             .prompt(#{message}, #{block_given? ? block : ack})`
  end

  def self.build_confirm_options(hash)
    {
      ok: 'Yes',
      cancel: 'No'
    }.merge(hash)
  end

  def self.build_log_options(hash)
    {
      type: :default,
      delay: 5000,
      close_on_click: true,
      max: 3,
      position: 'bottom right'
    }.merge(hash)
  end

  def self.construct_message(msg, opts = {})
    if opts[:icon]
      "<i class='fa fa-#{opts[:icon]} #{opts[:icon_class]}'/><span>#{msg}</span>"
    else
      msg
    end
  end

end
