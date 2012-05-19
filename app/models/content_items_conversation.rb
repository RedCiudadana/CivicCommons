class ContentItemsConversation < ActiveRecord::Base
  belongs_to :content_item
  belongs_to :conversation
end