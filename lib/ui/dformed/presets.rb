# Add autosizing to textareas and make them wider by default
DFormed::Registry.add_preset(:textarea, type: :textarea, class: :autosize, styles: { width: '300px' })

# Default date time overrides
DFormed::Registry.add_preset(:'datetime-local', type: :text, class: 'date-time-picker', attributes: { placeholder: 'Select a date & time...' })
DFormed::Registry.add_preset(:date, type: :text, class: 'date-picker', attributes: { placeholder: 'Select a date...' })
DFormed::Registry.add_preset(:time, type: :text, class: 'time-picker', attributes: { placeholder: 'Select a time...' })

# Multi Selects to select2
DFormed::Registry.add_preset(:multi_select, type: :multi_select, class: 'select-2')

DFormed::Registry.add_preset(:toggle, class: 'toggle yesno', type: :toggle)
