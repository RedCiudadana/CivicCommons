class SurveyResponse < ActiveRecord::Base
  attr_accessor :selected_option_ids, :validate_presence_of_selected_option
  has_many :selected_survey_options, :dependent => :destroy
  belongs_to :person
  belongs_to :survey
  validates_presence_of :person_id
  validates_uniqueness_of :person_id, :scope => :survey_id, :allow_blank => true, :allow_nil => true, :message => 'already exists'
  validate :selected_should_be_under_max_selected_options
  validate :presence_of_selected_options, :if => :validate_presence_of_selected_option?
  
  after_commit :send_survey_confirmation, :on => :create

  scope :sort_last_created_first, {:order=> 'created_at DESC'}

  delegate :id, :title, :type, :to => :survey, :prefix => true
  delegate :name, :to => :person, :prefix => true
  
  def validate_presence_of_selected_option?
    @validate_presence_of_selected_option ||= false
  end
  
  def conversation_id
    survey.surveyable_id if try(:survey).try(:surveyable).is_a?(Conversation)
  end
  
  def selected_option_ids=(option_ids=[])
    @selected_option_ids = option_ids
    @selected_option_ids.each do |option_id|
      self.selected_survey_options.build(:survey_option_id => option_id)
    end
  end
  
  def selected_option_ids
    selected_survey_options.collect(&:survey_option_id)
  end
  
  def selected_survey_option_titles
    selected_survey_options.collect{|selected_option| selected_option.survey_option.title }
  end

  def send_survey_confirmation
    Notifier.survey_confirmation(self).deliver
  end
  
  def selected_should_be_under_max_selected_options
    if self.survey && selected_option_ids.length > survey.max_selected_options
      self.errors[:selected_option_ids] << "You cannot select more than #{survey.max_selected_options} option(s)"
    end
  end
  def presence_of_selected_options
    if selected_option_ids.length < 1
      self.errors[:selected_option_ids] << "You must select at least one option"
    end
  end
  
end
