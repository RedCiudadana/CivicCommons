class ContentItemsPerson < ActiveRecord::Base
  belongs_to :content_item
  belongs_to :person
end