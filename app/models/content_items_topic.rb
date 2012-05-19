class ContentItemsTopic < ActiveRecord::Base
  belongs_to :content_item
  belongs_to :topic
end