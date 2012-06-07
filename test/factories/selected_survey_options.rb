FactoryGirl.define do
  factory :selected_survey_option do |f|
    f.survey_response_id 1
    f.survey_option_id 1
    f.sequence(:position) {|n| n }
  end
end