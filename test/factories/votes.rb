FactoryGirl.define do
  factory :vote do |f|
    f.surveyable_id 1
    f.surveyable_type 'Issue'
    f.end_date 1.weeks.from_now.to_date
    f.title 'This is a title'
    f.description  'Description here'
    f.options []
    f.max_selected_options 3
    f.person { |s| s.association(:registered_user) }
  end
end
