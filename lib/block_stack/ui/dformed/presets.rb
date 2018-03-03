
DFormed.add_preset(
  :multi_field,
  type: :multi_field,
  row_attributes:{
    class: ['animated', 'fadeIn']
  },
  add_button: {
    type: :button,
    class: 'btn btn-outline-success btn-sm',
    label: '<i class="fas fa-plus"/>',
    events: {
      events: :click,
      type: :ruby,
      event: "puts 'TEST'"
    }
  },
  remove_button: {
    type: :button,
    class: 'btn btn-outline-warning btn-sm',
    label: '<i class="fas fa-minus"/>'
  },
  up_button: {
    type: :button,
    class: 'btn btn-outline-info btn-sm',
    label: '<i class="fas fa-arrow-up"/>'
  },
  down_button: {
    type: :button,
    class: 'btn btn-outline-info btn-sm',
    label: '<i class="fas fa-arrow-down"/>'
  }
)

DFormed.add_preset(:date, type: :date, class: 'date-picker')
DFormed.add_preset(:time, type: :time, class: 'time-picker')
DFormed.add_preset(:date_time, type: :date_time, class: 'date-time-picker')

DFormed.add_preset(:boolean, type: :boolean, class: 'toggle yesno')

DFormed.add_preset(:text_area, type: :text_area, classes: 'autosize')
DFormed.add_preset(:json, type: :json, classes: 'autosize json')
DFormed.add_preset(:hash_field, type: :json, classes: 'autosize json')

# TODO Fix issue with select 2 fields in dformed where the element is changed and
#   tooptips are shown as raw text rather than html on validation
DFormed.add_preset(:multi_select, type: :multi_select, classes: 'select-2')
DFormed.add_preset(:select, type: :select, classes: 'select-2')

DFormed.add_preset(
  :flat_hash,
  type: :flat_hash,
  row_attributes:{
    class: ['animated', 'fadeIn']
  },
  add_button: {
    type: :button,
    class: 'btn btn-outline-success btn-sm',
    label: '<i class="fas fa-plus"/>',
    events: {
      events: :mouseup,
      type: :ruby,
      event: "after(0.1) { Loaders.load_all(element.closest('.dformed-flat-hash')) }"
    }
  },
  remove_button: {
    type: :button,
    class: 'btn btn-outline-warning btn-sm',
    label: '<i class="fas fa-minus"/>'
  },
  up_button: {
    type: :button,
    class: 'btn btn-outline-info btn-sm',
    label: '<i class="fas fa-arrow-up"/>'
  },
  down_button: {
    type: :button,
    class: 'btn btn-outline-info btn-sm',
    label: '<i class="fas fa-arrow-down"/>'
  }
)
