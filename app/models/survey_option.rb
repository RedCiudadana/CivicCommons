class SurveyOption < ActiveRecord::Base
  SURVEYABLE_TYPES = ['Issue', 'Conversation']
  attr_accessor :nested, 
                :weighted_votes_percentage, 
                :winner, # used by VoteProgressService
                :voted # used by VoteProgressService
  belongs_to :survey
  has_many :selected_survey_options, :dependent => :destroy
  validates_presence_of :survey_id, :unless => :nested
  validates_uniqueness_of :position, :scope => :survey_id, :allow_blank => true, :allow_nil => true, :unless => :nested
  validate :validate_title_or_description
  scope :position_sorted, {:order =>'position ASC, id ASC'}
  
  def validate_title_or_description
    if title.blank? && description.blank?
      self.errors.add(:title,'Either title must be filled, or description must be filled') 
    end
  end
end