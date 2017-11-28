
DFormed.add_preset(
  :multi_field,
  type: :multi_field,
  row_attributes:{
    class: ['animated', 'fadeIn']
  },
  add_button: {
    type: :button,
    class: 'btn btn-outline-success btn-sm fa fa-plus', label: ''
  },
  remove_button: {
    type: :button,
    class: 'btn btn-outline-warning btn-sm fa fa-minus', label: ''
  },
  up_button: {
    type: :button,
    class: 'btn btn-outline-info btn-sm fa fa-arrow-up', label: ''
  },
  down_button: {
    type: :button,
    class: 'btn btn-outline-info btn-sm fa fa-arrow-down', label: ''
  }
)

DFormed.add_preset(:date, type: :date, class: 'date-picker')
DFormed.add_preset(:time, type: :date, class: 'time-picker')
DFormed.add_preset(:'date-time', type: :date, class: 'date-time-picker')

DFormed.add_preset(:text_area, type: :text_area, classes: 'autosize')
DFormed.add_preset(:json, type: :json, classes: 'autosize')
