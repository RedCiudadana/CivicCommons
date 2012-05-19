class SurveyResponse < ActiveRecord::Base
  has_many :selected_survey_options, :dependent => :destroy
  belongs_to :person
  belongs_to :survey
  validates_presence_of :person_id
  validates_uniqueness_of :person_id, :scope => :survey_id, :allow_blank => true, :allow_nil => true, :message => 'already exists'
  after_commit :send_survey_confirmation, :on => :create

  scope :sort_last_created_first, {:order=> 'created_at DESC'}

  delegate :id, :title, :type, :to => :survey, :prefix => true
  delegate :name, :to => :person, :prefix => true
  
  def selected_survey_option_titles
    selected_survey_options.collect{|selected_option| selected_option.survey_option.title }
  end

  def send_survey_confirmation
    Notifier.survey_confirmation(self).deliver
  end
end
