module BlockStack
  def self.form_controller
    @form_controller ||= DFormed::Controller.new
  end

  def self.load_forms
    Element['.dform'].each_with_index do |form, id|
      next if form.attr('df_loaded')
      form_id = form.attr('df_name') || "form_#{id}"
      if form.attr('df_get_from')
        form_controller.download(form.attr('df_get_from'), form_id, form)
      else
        form_data = JSON.parse(form.attr('df_form_data'))
        form_controller.add_and_render(form_data, form_id, form)
      end
      form.attr('df_form_data', '')
      form.attr('df_loaded', true)
    end

    Element['.dform-save'].each do |btn, id|
      next unless btn.attr('df_name') && btn.attr('df_save_to')
      next if btn.attr('df_loaded')
      method = (btn.attr('df_method') || :post).downcase
      btn.on :click do |evt|
        btn.attr(:disabled, true)
        `alertify.closeLogOnClick(true).logPosition("bottom right").log("Saving form...");`
        case method
        when :post
          HTTP.post(btn.attr('df_save_to'), data: form_controller.values(btn.attr('df_name')).to_json, contentType: 'application/json') do |response|
            if response.json['status'] == :success
              `alertify.closeLogOnClick(true).logPosition("bottom right").success(#{response.json[:message] || "Successfully saved!"});`
              if url = btn.attr(:df_save_redirect)
                after(2) { `window.location.href = #{url}` }
              end
            else
              `alertify.closeLogOnClick(true).logPosition("bottom right").error(#{response.json[:message] || "Failed to save"});`
              btn.attr(:disabled, false)
            end
          end
        when :put
          HTTP.put(btn.attr('df_save_to'), data: form_controller.values(btn.attr('df_name')).to_json, contentType: 'application/json') do |response|
            `console.log(#{response})`
            if response.json['status'] == :success
              `alertify.closeLogOnClick(true).logPosition("bottom right").success(#{response.json[:message] || "Successfully saved!"});`
              if url = btn.attr(:df_save_redirect)
                after(2) { `window.location.href = #{url}` }
              end
            else
              `alertify.closeLogOnClick(true).logPosition("bottom right").error(#{response.json[:message] || "Failed to save"});`
              btn.attr(:disabled, false)
            end
          end
        end
      end
      btn.attr('df_loaded', true)
    end
  end
end
