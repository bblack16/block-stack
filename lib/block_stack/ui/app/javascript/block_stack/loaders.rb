# Various methods to load or reload elements based on the DOM
module Loaders

  def self.load_all(selector = 'body')
    # Main Menu slider
    Loaders.menu_slider(selector)

    Loaders.dformed(selector)

    # Load delete links
    Loaders.delete_model_buttons(selector)

    # Initialize tooltips and data tables
    Loaders.tooltips(selector)
    Loaders.data_tables(selector)

    # Initialize AnimateOnScroll scripts
    # Loaders.animate_on_scroll(selector)

    # Patch for alertify
    Loaders.alertify(selector)

    Loaders.date_pickers(selector)
    Loaders.toggle(selector)
    Loaders.select_2(selector)
    Loaders.ripple(selector)
    Loaders.floating_labels(selector)
    Loaders.autosize_textareas(selector)
    Loaders.baguette_box_galleries(selector)

    # Fires off any notices on the page
    Loaders.notices(selector)

    Loaders.lazy_load(selector)
  end

  def self.menu_slider(selector = 'body')
    Element[selector].find('#menu-toggle').on :click do |event|
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

  def self.delete_model_buttons(selector = 'body')
    Element[selector].find('.delete-model-btn').each do |elem|
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

  def self.tooltips(selector = 'body')
    Element[selector].find('[tooltip="true"],[data-toggle="tooltip"],[title]').JS.tooltip
  end

  def self.data_tables(selector = 'body')
    Element[selector].find('.data-table,.data_table').each do |table|
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

  def self.alertify(selector = 'body')
    `alertify.parent(document.body)`
  end

  # TODO Add calendar icon to inputs
  def self.date_pickers(selector = 'body')
    Element[selector].find('.date-time-picker').JS.flatpickr({ enableSeconds: true, enableTime: true, altInput: true }.to_n)
    Element[selector].find('.date-picker').JS.flatpickr({ altInput: true }.to_n)
    Element[selector].find('.time-picker').JS.flatpickr({ enableSeconds: true, enableTime: true, noCalendar: true}.to_n)
    # Element['input.date-time-picker'].each do |elem|
    #   elem.parent.append('<i class="far fa-calendar"></i>') if elem.parent.find('i.far.fa-calendar').empty?
    # end
  end

  def self.toggle(selector = 'body')
    Element[selector].find('input.toggle').each do |elem|
      parent = elem.parent
      elem.detach
      label = Element['<label class="switch"/>']
      slider = Element["<span class='slider round #{elem.attr(:class)}'\>"]
      label.append(elem, slider)
      parent.append(label)
    end
  end

  # TODO Add detection if the field is already loaded, otherwise this is destructive
  def self.select_2(selector = 'body')
    Element[selector].find('select.select-2').JS.select2({
			theme: 'bootstrap',
      allowClear: true
    }.to_n)
    Element[selector].find('select.select-2').each do |elem|
      elem.remove_class('select-2')
      elem.add_class('select-2-loaded')
    end
  end

  def self.ripple(selector = 'body')
    Element[selector].find('.ripple').on :click do |evt|
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

  def self.floating_labels(selector = 'body')
    Element[selector].find('.floating-label').find('input,textarea,select').on('focusout click change') do |evt|
      if evt.target.value.empty?
        evt.target.remove_class('has-value')
      else
        evt.target.add_class('has-value')
      end
    end
    Element[selector].find('.floating-label').find('input,textarea,select').trigger(:focusout)
  end

  def self.autosize_textareas(selector = 'body')
    Element[selector].find('textarea.autosize').each do |elem|
      elem.on :input do |evt|
        min_height = elem.attr('data-min-resize-height') || 0
        max_height = elem.attr('data-max-resize-height') || 400
        clone = evt.target.clone
        clone.css(:height, 'auto')
        clone.css(:width, "#{evt.target.width}px")
        Element['body'].append(clone)
        height = `#{clone}[0].scrollHeight`.to_i + 50
        height = min_height if height < min_height
        height = max_height if height > max_height
        evt.target.css(:height, "#{height}px")
        clone.remove
      end
    end
    Element[selector].find('textarea.autosize').trigger(:input)
  end

  def self.baguette_box_galleries(selector = 'body')
    Element[selector].find("img.baguette-image").each do |elem|
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

  def self.dformed(selector = 'body')
    BlockStack.load_forms
  end

  def self.notices(selector = 'body')
    Element[selector].find('#notice').each do |elem|
      Alert.log(elem.html, type: elem.attr('notice-severity'), delay: 6000, position: 'top right') if elem.text.strip != ''
    end
  end

  def self.lazy_load(selector = 'body')
    @lazy_load ||= `new LazyLoad()`
  end
end
