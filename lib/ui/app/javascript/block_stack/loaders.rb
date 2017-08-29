# Various methods to load or reload elements based on the DOM
module Loaders

  def self.load_all

    # Initialize tooltips and data tables
    Loaders.tooltips
    Loaders.data_tables

    # Initialize AnimateOnScroll scripts
    Loaders.animate_on_scroll

    # Patch for alertify
    Loaders.alertify

    Loaders.date_pickers
    Loaders.select_2
    Loaders.ripple
    Loaders.floating_labels
    Loaders.autosize_textareas
    # Loaders.baguette_box_galleries
    Loaders.slider

    Loaders.dformed
  end

  def self.slider
    Element['#menu-toggle'].on :click do |event|
      menu = Element['#menu']
      if menu.has_class?(:hide)
        menu.remove_class(:hide)
        Element['#menu-toggle'].remove_class(:dark)
        Element['body'].remove_class(:'closed-menu')
      else
        menu.add_class(:hide)
        Element['#menu-toggle'].add_class(:dark)
        Element['body'].add_class(:'closed-menu')
      end
    end
  end

  def self.tooltips
    Element['[tooltip="true"],[data-toggle="tooltip"]'].JS.tooltip
  end

  def self.data_tables
    Element['.data-table,.data_table'].each do |table|
      opts = { buttons: [:copy, :excel, :colvis, :print] }
      opts[:ajax] = table.attr('dt_ajax') if table.attr('dt_ajax')
      opts['oLanguage'] = {
        sSearch: '',
        sLengthMenu: 'Rows per page: _MENU_',
        sSearchPlaceholder: 'Filter'
      }
      data_table = table.JS.dataTable(opts.to_n)
      every(10, data_table.JS.reload) if opts[:ajax]
    end
  end

  def self.animate_on_scroll
    `AOS.init();`
  end

  def self.alertify
    `alertify.parent(document.body)`
  end

  def self.date_pickers
    Element['.date-picker'].JS.dateDropper
    Element['.time-picker'].JS.timeDropper({ mouseWheel: true, format: 'HH:mm' }.to_n)
  end

  def self.select_2
    Element['.select-2'].JS.select2({
      tags: true,
			theme: 'bootstrap',
      allowClear: true
    }.to_n)
    Element['.select-2'].each do |elem|
      elem.parent.append(Element['<span class="fa fa-caret-down" style="position: absolute; right: 5px"/>'])
    end
  end

  def self.ripple
    Element['.ripple'].on :click do |evt|
      evt.prevent_default
      offset = evt.current_target.offset
      xpos = evt.page_x - offset.left
      ypos = evt.page_y - offset.top

      div = Element['<div/>']
      div.add_class('ripple-effect')
      div.css(:height, evt.current_target.height)
      div.css(:width, evt.current_target.height)
      div.css(
        top: ypos - (div.height / 2),
        left: xpos - (div.width / 2),
        background: evt.current_target.data('ripple-color')
      )
      div.append_to(evt.current_target)

      after(2) do
        div.remove
      end
    end
  end

  def self.floating_labels
    Element['.floating-label'].find('input,textarea,select').on('focusout click change') do |evt|
      if evt.target.value.empty?
        evt.target.remove_class('has-value')
      else
        evt.target.add_class('has-value')
      end
    end
    Element['.floating-label'].find('input,textarea,select').trigger(:focusout)
  end

  def self.autosize_textareas
    Element['textarea.autosize'].on :input do |evt|
      evt.target.css(:height, 'auto')
      evt.target.css(:height, `#{evt.target}[0].scrollHeight`.to_s + 'px')
    end
  end

  def self.baguette_box_galleries
    `baguetteBox.run('.gallery');`
  end

  def self.dformed
    FORM_CONTROLLER = DFormed::Controller.new
    Element['.dform'].each_with_index do |form, id|
      form_id = form.attr('df_name') || "form_#{id}"
      if form.attr('df_get_from')
        FORM_CONTROLLER.download(form.attr('df_get_from'), form_id, form)
      else
        form_data = JSON.parse(form.attr('df_form_data'))
        FORM_CONTROLLER.add_and_render(form_data, form_id, form)
      end
      form.attr('df_form_data', '')
    end

    Element['.dform-save'].each do |btn, id|
      next unless btn.attr('df_name') && btn.attr('df_save_to')
      method = btn.attr('df_method') || :post
      btn.on :click do |evt|
        btn.attr(:disabled, true)
        `alertify.closeLogOnClick(true).logPosition("bottom right").log("Saving form...");`
        HTTP.post(btn.attr('df_save_to'), data: FORM_CONTROLLER.values(btn.attr('df_name')).to_json) do |response|
          `console.log(#{response})`
          if response.json['status'] == :success
            `alertify.closeLogOnClick(true).logPosition("bottom right").success(#{response.json[:message] || "Successfully saved!"});`
            if url = btn.attr(:df_save_redirect)
              `window.location.href = #{url}`
            end
          else
            `alertify.closeLogOnClick(true).logPosition("bottom right").error(#{response.json[:message] || "Failed to save"});`
            btn.attr(:disabled, false)
          end
        end
      end
    end
  end
end
