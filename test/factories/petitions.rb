FactoryGirl.define do
  factory :petition do |f|
    f.association :conversation
    f.association :person
    f.title 'Title here'
    f.description 'Description here'
    f.resulting_actions 'Resulting Actions here'
    f.signature_needed 2
    f.signers { |signers| [signers.association(:person)] }
  end

  factory :unsigned_petition, :parent => :petition do |f|
    f.signers []
  end
end