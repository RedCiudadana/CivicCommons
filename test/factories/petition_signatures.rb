FactoryGirl.define do
  factory :petition_signature do |f|
    f.association :petition
    f.association :person
  end
end