FactoryGirl.define do
  factory :survey_response do |f|
    f.association :person, :factory => :registered_user
    f.association :survey, :factory => :vote
    # f.selected_survey_options{|selected_survey_options| [selected_survey_options.association(:selected_survey_option)]}
  end

  factory :vote_survey_response,:class=>SurveyResponse do |f|
    f.association :person, :factory => :registered_user
    f.association :survey, :factory => :vote
    # f.selected_survey_options {|selected_survey_options| [selected_survey_options.association(:selected_survey_option)]}
  end
end