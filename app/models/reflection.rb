class Reflection < ActiveRecord::Base
  belongs_to :person, :foreign_key => "owner"

  validates_presence_of :title
  validates_presence_of :details
end
