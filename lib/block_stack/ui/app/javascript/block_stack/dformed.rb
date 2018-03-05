# TODO Add section and multifield collapse support

module BlockStack
  def self.form_controller
    @form_controller ||= DFormed::Controller.new
  end

  def self.load_forms
    Element['.dform'].each_with_index do |form, id|
      next if form.attr('df-loaded')
      form_id = form.attr('df-name') || "form_#{id}"
      if form.attr('df-get-from')
        form_controller.download(form.attr('df-get-from'), form_id, form)
      else
        form_data = JSON.parse(form.attr('df-form-data'))
        form_controller.add_and_render(form_id, form_data, form)
      end
      form.attr('df-form-data', '')
      form.attr('df-loaded', true)
      if save_btn = Element[".dform-save[df-name=#{form.attr('df-name')}]"]
        begin
          form.find('input').keypress do |evt|
            save_btn.click if `#{evt}.which == 13`
          end
        rescue => e
          # TODO Figure out why this fails in older versions of Opal
          puts "ERROR: Failed to register DFormed on enter event: #{e}"
        end
      end
    end

    Element['.dform-save'].each do |btn, id|
      next unless btn.attr('df-name') && btn.attr('df-save-to')
      next if btn.attr('df-loaded')
      method = (btn.attr('df-method') || :post).downcase
      btn.on :click do |evt|
        btn.attr(:disabled, true)
        `alertify.closeLogOnClick(true).logPosition("bottom right").log("Saving form...");`

        HTTP.send(method, btn.attr('df-save-to'), data: form_controller.values(btn.attr('df-name')).to_json, contentType: 'application/json').then do |response|
          # `console.log(#{response})`
          if response.json['status'] == :success
            `alertify.closeLogOnClick(true).logPosition("bottom right").success(#{response.json[:message] || "Successfully saved!"});`
            mark_form_invalid(btn.attr('df-name'), {})
            if url = btn.attr('df-save-redirect')
              after(1) { `window.location.href = #{url}` }
            end
          else
            Alert.send(response.json[:result].is_a?(Hash) ? :warn : :error, response.json[:message] || "Failed to save")
            mark_form_invalid(btn.attr('df-name'), response.json[:result])
            btn.attr(:disabled, false)
          end
        end.fail do |response|
          Alert.send(response.json[:result].is_a?(Hash) ? :warn : :error, response.json[:message] || "Failed to save")
          mark_form_invalid(btn.attr('df-name'), response.json[:result])
          btn.attr(:disabled, false)
        end
      end
      btn.attr('df-loaded', true)
    end
  end

  def self.mark_form_invalid(name, errors)
    return unless errors.is_a?(Hash)
    form_controller.form(name).tap do |form|
      errors.each do |field_name, messages|
        message_list = messages.size == 1 ? "<span class='dformed-invalid-message'>#{messages.first}</span>" : "<ul class='dformed-invalid-message'><li>#{messages.join('</li><li>')}</li></ul>"
        message = "<i class='dformed-invalid-warning fa fa-exclamation-circle'/>#{message_list}"
        form.field(field_name).tap do |field|
          field.add_class(:invalid)
          field.remove_class(:valid)
          next unless field.element.is(':visible')
          field.add_attribute(
            title: message,
            'data-toggle': :tooltip,
            'data-placement': :right,
            'data-html': true
          )
          field.element.JS.tooltip(:show)
        end
      end

      form.fields.each do |field|
        next if errors.keys.include?(field.name)
        field.remove_class(:invalid)
        field.element.JS.tooltip(:dispose) rescue nil
      end
    end
  end
end
