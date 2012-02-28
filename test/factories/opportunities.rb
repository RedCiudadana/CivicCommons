# Read about factories at http://github.com/thoughtbot/factory_girl

Factory.define :opportunity do |f|
  f.association :conversation, :factory => :conversation
end