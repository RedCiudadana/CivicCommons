class Action < ActiveRecord::Base
  belongs_to :conversation
  belongs_to :actionable, :polymorphic => true
  validates_presence_of :conversation_id,
                        :actionable_id,
                        :actionable_type

  # the other end of actionable must have participants method
  delegate :participants, :to => :actionable

end
