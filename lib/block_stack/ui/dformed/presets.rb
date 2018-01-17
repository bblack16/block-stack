
DFormed.add_preset(
  :multi_field,
  type: :multi_field,
  row_attributes:{
    class: ['animated', 'fadeIn']
  },
  add_button: {
    type: :button,
    class: 'btn btn-outline-success btn-sm',
    label: '<i class="fas fa-plus"/>'
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

DFormed.add_preset(:text_area, type: :text_area, classes: 'autosize')
DFormed.add_preset(:json, type: :json, classes: 'autosize')
