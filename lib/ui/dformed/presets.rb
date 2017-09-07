# Add autosizing to textareas and make them wider by default
DFormed::Registry.add_preset(:textarea, type: :textarea, class: :autosize, styles: { width: '300px' })

# Default date time overrides
DFormed::Registry.add_preset(:'datetime-local', type: :text, class: 'date-time-picker')
DFormed::Registry.add_preset(:'date', type: :text, class: 'date-picker')
DFormed::Registry.add_preset(:'time', type: :text, class: 'time-picker')
