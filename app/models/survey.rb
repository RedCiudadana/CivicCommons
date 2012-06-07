class Survey < ActiveRecord::Base
  SURVEY_TYPES = ['Vote']#, 'Poll']
  belongs_to :person
  belongs_to :surveyable, :polymorphic => true
  has_one :action, :as => :actionable, :dependent => :destroy
  has_many :options, :class_name => 'SurveyOption', :foreign_key => 'survey_id', :dependent => :destroy
  has_many :survey_responses, :dependent => :restrict
  has_many :respondents, :through => :survey_responses, :source => :person
  validates_presence_of :max_selected_options, :title, :end_date
  validates_numericality_of :max_selected_options, :only_integer => true
  accepts_nested_attributes_for :options, :reject_if => :all_blank, :allow_destroy => true
  after_save :create_or_update_action, :if => :attached_to_conversation?
  after_save :send_end_notification_email_later
  
  alias_method :participants, :respondents

  def attached_to_conversation?
    surveyable && surveyable.is_a?(Conversation)
  end
  
  def create_or_update_action
    if self.action.present?
      self.action.update_attributes(:conversation_id => self.surveyable_id) if self.surveyable_id_changed?
    else
      self.build_action(:conversation_id => self.surveyable_id).save if self.surveyable_id.present?
    end
  end
  
  def conversation_id
    self.surveyable_id if attached_to_conversation?
  end
  
  def days_until_end_date
    (end_date - Date.today).to_i if end_date && end_date > Date.today
  end

  def show_progress_now?
    show_progress? && expired?
  end

  def send_end_notification_email
    unless end_notification_email_sent
      Survey.transaction do
        survey_responses.each do |response|
          Notifier.survey_ended(response.person, response.survey).deliver
        end

        self.end_notification_email_sent = true
        self.save
      end
    end
  end

  def send_end_notification_email_later
    self.delay(:run_at => end_date).send_end_notification_email if end_date_changed?
  end

  def active?
    start_date.blank? || (start_date && start_date <= Date.today)
  end

  def expired?
    !end_date.blank? && end_date.past?
  end

end
