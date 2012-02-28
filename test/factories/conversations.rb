# Read about factories at http://github.com/thoughtbot/factory_girl

Factory.define :conversation do |f|
  f.started_at ""
  f.finished_at ""
  f.summary "MyString"
  f.sequence(:title) {|n| "Some Random Title #{n}" }
  f.sequence(:cached_slug) {|n| "some-random-title-#{n}" }
  f.zip_code "48105"
  f.issues { |c| [c.association(:issue)] }
  f.from_community false
  f.association :person, :factory => :admin_person
end

Factory.define :user_generated_conversation, :parent => :conversation do |f|
  f.contributions { |c| [c.association(:contribution)] }
  f.from_community true
  f.association :person, :factory => :registered_user
end

FactoryGirl.define do
  factory :conversation_with_contribution, class: Conversation, parent: :conversation do
    after_create do |conversation, evaluator|
      conversation.contributions = [Factory.create(:contribution, conversation: conversation)]
    end
  end

  factory :conversation_with_contributions, class: Conversation, parent: :conversation do
    after_create do |conversation, evaluator|
      conversation.contributions = [
        Factory.create(:contribution, conversation: conversation),
        Factory.create(:contribution, conversation: conversation)
      ]
    end
  end
end