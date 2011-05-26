class Person < ActiveRecord::Base

  include ActionView::Helpers::TextHelper
  include Regionable
  include GeometryForStyle
  include Marketable

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, and :timeoutable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable, :lockable,
         :omniauthable

  attr_accessor :organization_name, :send_welcome, :create_from_auth, :facebook_unlinking, :send_email_change_notification

  # Setup accessible (or protected) attributes for your model
  attr_accessible :name, :first_name, :last_name, :email, :password, :password_confirmation, :bio, :top, :zip_code, :admin, :validated,
                  :avatar, :remember_me, :daily_digest, :create_from_auth, :facebook_unlinking

  has_one :facebook_authentication, :class_name => 'Authentication', :conditions => {:provider => 'facebook'}
  has_many :authentications, :dependent => :destroy
  has_many :content_items, :foreign_key => 'person_id', :dependent => :restrict 
  has_many :content_templates, :foreign_key => 'person_id', :dependent => :restrict 
  has_many :contributions, :foreign_key => 'owner', :uniq => true, :dependent => :restrict 
  has_many :managed_issue_pages, :foreign_key => 'person_id', :dependent => :restrict 
  has_many :rating_groups, :dependent => :restrict
  has_many :subscriptions, :dependent => :destroy
  has_and_belongs_to_many :conversations, :join_table => 'conversations_guides', :foreign_key => :guide_id

  has_many :contributed_conversations, :through => :contributions, :source => :conversation, :uniq => true, :dependent => :restrict 
  has_many :contributed_issues, :through => :contributions, :source => :issue, :uniq => true, :dependent => :restrict 

  validates_length_of :email, :within => 6..255, :too_long => "please use a shorter email address", :too_short => "please use a longer email address"
  validates_length_of :zip_code, :within => (5..10), :allow_blank => true, :allow_nil => true, :if => :validate_zip_code?
  validates_presence_of :zip_code, :message => 'Please enter zipcode.', :if => :validate_zip_code?
  validates_presence_of :name

  has_friendly_id :name, :use_slug => true, :strip_non_ascii => true

  # Ensure format of salt
  # Commented out because devise 1.2.RC doesn't store password_salt column anymore, if it uses bcrypt
  # validates_with PasswordSaltValidator

  has_attached_file :avatar,
    :styles => {
      :small => "20x20#",
      :medium => "40x40#",
      :standard => "70x70#",
      :large => "185x185#"},
    :storage => :s3,
    :s3_credentials => S3Config.credential_file,
    :default_url => '/images/avatar_70.gif',
    :path => ":attachment/:id/:style/:filename"

  validates_attachment_content_type :avatar,
                                    :content_type => %w(image/jpeg image/gif image/png image/jpg image/x-png image/pjpeg),
                                    :message => "Not a valid image file."
  process_in_background :avatar

  scope :participants_of_issue, lambda{ |issue|
      joins(:conversations => :issues).where(['issue_id = ?',issue.id]).select('DISTINCT(people.id),people.*') if issue
    }

  scope :real_accounts, where("proxy is not true")
  scope :proxy_accounts, where(:proxy => true)
  scope :confirmed_accounts, where("confirmed_at is not null")
  scope :unconfirmed_accounts, where(:confirmed_at => nil)

  after_create :notify_civic_commons
  before_save :check_to_send_welcome_email
  after_save :send_welcome_email, :if => :send_welcome?

  around_update :check_to_notify_email_change, :if => :send_email_change_notification?

  def check_to_notify_email_change
    old_email, new_email = self.email_change
    yield
    Notifier.email_changed(old_email, new_email).deliver if old_email && new_email
  end

  def newly_confirmed?
    confirmed_at_changed? && confirmed_at_was.blank? && !confirmed_at.blank?
  end

  def check_to_send_welcome_email
    @send_welcome = true if newly_confirmed?
  end

  def create_from_auth?
    @create_from_auth || false
  end

  def avatar_width_for_style(style)
    geometry_for_style(style, :avatar).width.to_i
  end

  def avatar_height_for_style(style)
    geometry_for_style(style, :avatar).height.to_i
  end

  def facebook_unlinking?
    @facebook_unlinking || false
  end

  def name=(value)
    @name = value
    self.first_name, self.last_name = self.class.parse_name(value)
  end

  def name
    @name ||= ("%s %s" % [self.first_name, self.last_name]).strip
  end

  def notify_civic_commons
    Notifier.new_registration_notification(self).deliver
  end

  def send_welcome?
    @send_welcome
  end

  def send_email_change_notification?
    @send_email_change_notification || false
  end

  def send_welcome_email
    Notifier.welcome(self).deliver
    @send_welcome = false
  end

  def self.find_all_by_name(name)
    first, last = parse_name(name)
    where(:first_name => first, :last_name => last)
  end

  def self.find_confirmed_order_by_recency
    Person.order('confirmed_at DESC').where('confirmed_at IS NOT NULL').where('locked_at IS NULL')
  end

  def self.find_confirmed_order_by_last_name(letter = nil)
    if letter.nil?
      Person.find(:all,
                  :select => "*, IF(last_name IS NULL OR last_name='' OR UCASE(SUBSTR(last_name, 1) NOT BETWEEN 'A' AND 'Z'), 1, 0) as blank_last_name",
                  :conditions => 'confirmed_at IS NOT NULL and locked_at IS NULL',
                  :order => 'blank_last_name, last_name, first_name ASC'
                 )
    else
      Person.order('last_name, first_name ASC').where('confirmed_at IS NOT NULL').where("last_name like '#{letter}%'").where('locked_at IS NULL')
    end
  end

  # Takes a full name and return an array of first and last name
  # Examples
  #  "Wendy" => ["Wendy", ""]
  #  "Wendy Smith" => ["Wendy", "Smith"]
  #  "Wendy van Buren" => ["Wendy", "van Buren"]
  #
  def self.parse_name(name)
    first, *last = name.split(' ')
    last = last.try(:join, " ") || ""
    return first, last
  end

  def create_proxy
    self.email = (first_name + last_name).gsub(/['\s]/,'').downcase + "@example.com"
    self.password = 'p4s$w0Rd'
    self.proxy = true
  end

  def subscriptions_include?(subscribable)
    subscriptions.map(&:subscribable).include?(subscribable)
  end

  def unlink_from_facebook(person_hash)
    ActiveRecord::Base.transaction do
      self.email = person_hash[:email]
      self.password = person_hash[:password]
      self.password_confirmation = person_hash[:password_confirmation]
      self.facebook_unlinking = true
      self.send_email_change_notification = true # sends email change notification
      save!
      self.facebook_authentication.destroy
    end
  rescue
    self
  end

  def avatar_path(style='')
    self.avatar.path(style)
  end

  # Implement Marketable method
  def is_marketable?
    return false if skip_email_marketing

    newly_confirmed? ? true : false
  end

  # https://graph.facebook.com/#{uid}/picture
  # optional params: type=small|square|large
  # square (50x50), small (50 pixels wide, variable height), and large (about 200 pixels wide, variable height):
  def facebook_profile_pic_url(type = :square)
    "https://graph.facebook.com/#{facebook_authentication.uid}/picture?type=#{type}" if facebook_authenticated?
  end

  def facebook_authenticated?
    !facebook_authentication.blank?
  end

  def link_with_facebook(authentication)
    ActiveRecord::Base.transaction do
      self.facebook_authentication = authentication
      self.encrypted_password = ''
      self.create_from_auth = true
      save!
      facebook_authentication.persisted?
    end
  end

  def conflicting_email?(other_email)
    if other_email.blank? || (other_email.to_s.downcase.strip == email.to_s.downcase.strip)
      false
    else
      true
    end
  end

  def merge_account(person_to_merge)
    if person_to_merge.class.name == 'Person' && id == person_to_merge.id
      return false
    end

    puts 'beginning rake task' unless Rails.env.test?
    begin
      transaction do
        puts 'begin:   updating FROM account confirmed_at' unless Rails.env.test?
        person_to_merge.confirmed_at = nil
        person_to_merge.save!
        puts 'updated: ' + pluralize(1, 'record') unless Rails.env.test?
        puts 'end:     updating FROM account confirmed_at' unless Rails.env.test?

        puts 'begin:   updating contributions' unless Rails.env.test?
        updated_record_count = 0
        person_to_merge.contributions.map do |contribution|
          contribution.owner = id
          contribution.save!
          updated_record_count += 1
        end
        puts 'updated: ' + pluralize(updated_record_count, 'record') unless Rails.env.test?
        puts 'end:     updating contributions' unless Rails.env.test?

        puts 'begin:   updating rating groups' unless Rails.env.test?
        # this will fail if the user has ratings for both accounts
        updated_record_count = 0
        RatingGroup.where('person_id = ?', person_to_merge.id).map do |rating_group|
          rating_group.person_id = id
          rating_group.save!
          updated_record_count += 1
        end
        puts 'updated: ' + pluralize(updated_record_count, 'record') unless Rails.env.test?
        puts 'end:     updating rating groups' unless Rails.env.test?

        puts 'begin:   updating conversation owners' unless Rails.env.test?
        updated_record_count = 0
        Conversation.where('owner = ?', person_to_merge.id).map do |conversation|
          conversation.owner = id
          conversation.save!
          updated_record_count += 1
        end
        puts 'updated: ' + pluralize(updated_record_count, 'record') unless Rails.env.test?
        puts 'end:     updating conversation owners' unless Rails.env.test?

        puts 'begin:   updating subscriptions' unless Rails.env.test?
        updated_record_count = 0
        # Make the TO account follow all the same conversations/issues as the FROM account
        Subscription.where(person_id: person_to_merge.id).each do |subscription|
          Subscription.create_unless_exists(self, subscription.subscribable)
          updated_record_count += 1
        end
        puts 'updated: ' + pluralize(updated_record_count, 'record') unless Rails.env.test?
        puts 'end:     updating subscriptions' unless Rails.env.test?

        puts 'begin:   updating visits' unless Rails.env.test?
        updated_record_count = 0
        Visit.where('person_id = ?', person_to_merge.id).map do |visit|
          visit.person_id = id
          visit.save!
          updated_record_count += 1
        end
        puts 'updated: ' + pluralize(updated_record_count, 'record') unless Rails.env.test?
        puts 'end:     updating visits' unless Rails.env.test?

        puts 'begin:   updating content_templates' unless Rails.env.test?
        updated_record_count = 0
        person_to_merge.content_templates.map do |content_template|
          content_template.person_id = id
          content_template.save!
          updated_record_count += 1
        end
        puts 'updated: ' + pluralize(updated_record_count, 'record') unless Rails.env.test?
        puts 'end:     updating content_templates' unless Rails.env.test?

        puts 'begin:   updating content_items' unless Rails.env.test?
        updated_record_count = 0
        person_to_merge.content_items.map do |content_item|
          content_item.person_id = id
          content_item.save!
          updated_record_count += 1
        end
        puts 'updated: ' + pluralize(updated_record_count, 'record') unless Rails.env.test?
        puts 'end:     updating content_items' unless Rails.env.test?

        puts 'begin:   updating managed_issue_pages' unless Rails.env.test?
        updated_record_count = 0
        person_to_merge.managed_issue_pages.map do |managed_issue_page|
          managed_issue_page.person_id = id
          managed_issue_page.save!
          updated_record_count += 1
        end
        puts 'updated: ' + pluralize(updated_record_count, 'record') unless Rails.env.test?
        puts 'end:     updating managed_issue_pages' unless Rails.env.test?

      end # transaction

    rescue ActiveRecord::RecordInvalid => exception
      puts exception.message unless Rails.env.test?
      puts exception.backtrace.join("\n") unless Rails.env.test?
    end # begin

    puts 'ending rake task' unless Rails.env.test?
    return Person.find(person_to_merge.id).confirmed_at.nil?
  end

  # Overiding Devise::Models::DatabaseAuthenticatable
  # due to needing to set encrypted_password to blank, so that it doesn't error out when it is set to nil
  def valid_password?(password)
    encrypted_password.blank? ? false : super
  end

  def validate_zip_code?
    if create_from_auth?
      false
    elsif facebook_unlinking?
      false
    else
      true
    end
  end

  # Add the email subscription signup as a delayed job
  def subscribe_to_marketing_email
    if Civiccommons::Config.mailer['mailchimp']
      Delayed::Job.enqueue Jobs::SubscribeToMarketingEmailJob.new(Civiccommons::Config.mailer['api_token'],
                                                                  Civiccommons::Config.mailer['list'],
                                                                  email,
                                                                  {:FNAME => first_name, :LNAME => last_name},
                                                                  'html',
                                                                  false)

      Rails.logger.info("Success. Added #{name} with email #{email} to email queue.")
    else
      Rails.logger.info("Auto-Subscription to MailChimp is off...")
    end
  end

  def self.create_from_auth_hash(auth_hash)
    new_person = new(:name => auth_hash['user_info']['name'],
        :email => Authentication.email_from_auth_hash(auth_hash),
        :encrypted_password => '',
        :create_from_auth => true
      )
    new_person.save
    new_person.confirm! if new_person.persisted?
    new_person.authentications << Authentication.new_from_auth_hash(auth_hash)
    new_person
  end

  # overriding devise's recoverable
  def self.send_reset_password_instructions(attributes={})
    recoverable = find_or_initialize_with_errors(authentication_keys, attributes, :not_found)
    recoverable.send_reset_password_instructions if recoverable.persisted? && !recoverable.facebook_authenticated?
    recoverable
  end

protected

  def password_required?
    if facebook_authenticated?
      facebook_unlinking? ? true : false
    else
      (!persisted? && !create_from_auth?) || password.present? || password_confirmation.present?
    end
  end

end
