Document.on 'ready turbolinks:load' do
  form = Element['#form']
  FORM_CONTROLLER.add_and_render(JSON.parse(form.attr('df_form')), 'form', '#form')
  form.attr('df_form', '')
  Element['#save'].on :click do |evt|
    values = FORM_CONTROLLER.values('form')
    puts values
    HTTP.post form.attr(:df_save_to), data: values.to_json do |response|
      puts response
    end
  end
end
