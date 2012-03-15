class Survey < ActiveRecord::Base
  SURVEY_TYPES = ['Vote']#, 'Poll']
  belongs_to :surveyable, :polymorphic => true
  has_many :options, :class_name => 'SurveyOption', :foreign_key => 'survey_id', :dependent => :destroy
  has_many :survey_responses, :dependent => :restrict
  validates_presence_of :max_selected_options, :title, :end_date, :type
  validates_numericality_of :max_selected_options, :only_integer => true
  accepts_nested_attributes_for :options, :reject_if => :all_blank, :allow_destroy => true
  after_save :send_end_notification_email_later

  def days_until_end_date
    (end_date - Date.today).to_i if end_date && end_date.future?
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
    !end_date.blank? && (end_date.today? || end_date.past? )
  end

end
