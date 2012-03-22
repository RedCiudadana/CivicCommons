Factory.define :vote do |f|
  f.end_date 1.weeks.from_now.to_date
  f.title 'This is a title'
  f.description  'Description here'
  f.options []
  f.max_selected_options 3
end