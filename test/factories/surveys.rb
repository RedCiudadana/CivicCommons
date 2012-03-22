FactoryGirl.define do |f|
  factory :survey, :class => Survey do |survey|
    survey.end_date 1.weeks.from_now.to_date
    survey.title 'This is a title'
    survey.description  'Description here'
    survey.options []
    survey.max_selected_options 3
    survey.type 'Vote'
  end

  factory :survey_with_options, :parent => :survey do |survey|
    after_create do |new_survey|
      new_survey.options(Factory.create :survey_option, survey: new_survey)
    end
  end
end