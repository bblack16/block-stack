# Various methods to load or reload elements based on the DOM
module Loaders

  def self.load_all
    # Main Menu slider
    Loaders.menu_slider

    Loaders.dformed

    # Load delete links
    Loaders.delete_model_buttons

    # Initialize tooltips and data tables
    Loaders.tooltips
    Loaders.data_tables

    # Initialize AnimateOnScroll scripts
    # Loaders.animate_on_scroll

    # Patch for alertify
    Loaders.alertify

    Loaders.date_pickers
    Loaders.toggle
    Loaders.select_2
    Loaders.ripple
    Loaders.floating_labels
    Loaders.autosize_textareas
    Loaders.baguette_box_galleries

    # Fires off any notices on the page
    Loaders.notices

    # Loaders.lazy_load
  end

  def self.menu_slider
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

  def self.delete_model_buttons
    Element['.delete-model-btn'].each do |elem|
      elem.on :click do |evt|
        url = elem.attr(:'del-url')
        evt.prevent_default

        Alert.confirm('Are you sure?') do |e|
          elem.attr('disabled', true)
          HTTP.delete(url) do |response|
            if response.json[:status] == :success
              Alert.success("Successfully deleted")
              BlockStack.redirect(elem.attr('re-url') || '/', 1)
            else
              Alert.error("Failed to delete")
              elem.attr('disabled', false)
            end
          end
        end
      end
    end
  end

  def self.tooltips
    Element['[tooltip="true"],[data-toggle="tooltip"],[title]'].JS.tooltip
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

  # def self.animate_on_scroll
  #   `AOS.init();`
  # end

  def self.alertify
    `alertify.parent(document.body)`
  end

  # TODO Add calendar icon to inputs
  def self.date_pickers
    Element['.date-time-picker'].JS.flatpickr({ enableSeconds: true, enableTime: true, altInput: true }.to_n)
    Element['.date-picker'].JS.flatpickr({ altInput: true }.to_n)
    Element['.time-picker'].JS.flatpickr({ enableSeconds: true, enableTime: true, noCalendar: true}.to_n)
  end

  def self.toggle
    Element['input.toggle'].each do |elem|
      parent = elem.parent
      elem.detach
      label = Element['<label class="switch"/>']
      slider = Element["<span class='slider round #{elem.attr(:class)}'\>"]
      label.append(elem, slider)
      parent.append(label)
    end
  end

  def self.select_2
    Element['.select-2'].JS.select2({
			theme: 'bootstrap',
      allowClear: true
    }.to_n)
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
      clone = evt.target.clone
      clone.css(:height, 'auto')
      Element['body'].append(clone)
      evt.target.css(:height, `#{clone}[0].scrollHeight`.to_s + 'px')
      clone.remove
    end
    Element['textarea.autosize'].trigger(:input)
  end

  def self.baguette_box_galleries
    Element["img.baguette-image"].each do |elem|
      parent = elem.parent
      elem.detach
      gallery = Element["<div class='gallery'/>"]
      wrapper = Element["<a href='#{elem.attr(:src)}'/>"]
      gallery.append(wrapper)
      wrapper.append(elem)
      parent.append(gallery)
    end
    `baguetteBox.run('.gallery');`
  end

  def self.dformed
    BlockStack.load_forms
  end

  def self.notices
    Element['#notice'].each do |elem|
      Alert.log(elem.html, type: elem.attr('notice-severity'), delay: 6000, position: 'top right') if elem.text.strip != ''
    end
  end

  def self.lazy_load
    `lazyload();`
  end
end
