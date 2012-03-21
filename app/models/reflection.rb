class Reflection < ActiveRecord::Base
  belongs_to :person, :foreign_key => "owner"
  belongs_to :conversation

  validates_presence_of :title
  validates_presence_of :details

  alias_attribute :participants, :owner
end
