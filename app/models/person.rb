class Person < ActiveRecord::Base
  extend FriendlyId
  include Regionable
  include GeometryForStyle
  include UnsubscribeSomeone

  searchable :if => :confirmed?, :unless => :locked?,
    :ignore_attribute_changes_of => [ :updated_at, :failed_attempts, :current_sign_in_at, :last_sign_in_at, :current_sign_in_ip, :confirmed_at, :sign_in_count, :avatar_cached_image_url ] do
    text :first_name, :boost => 2, :default_boost => 2
    text :last_name, :boost => 2, :default_boost => 2
    text :bio, :stored => true, :boost => 1, :default_boost => 1 do
      Sanitize.clean(bio, :remove_contents => ['style','script'])
    end
  end

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, and :timeoutable
  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :trackable,
         :validatable,
         :confirmable,
         :lockable,
         :omniauthable

  attr_accessor :send_welcome,
                :create_from_auth,
                :facebook_unlinking,
                :send_email_change_notification,
                :require_zip_code

  # Setup accessible attributes
  attr_accessible :name,
                  :first_name,
                  :last_name,
                  :email,
                  :password,
                  :password_confirmation,
                  :bio,
                  :website,
                  :twitter_username,
                  :zip_code,
                  :admin,
                  :validated,
                  :avatar,
                  :remember_me,
                  :daily_digest,
                  :create_from_auth,
                  :facebook_unlinking

  # Setup protected attributes
  attr_protected :admin

  has_many :authentications, :dependent => :destroy
  has_many :organization_members
  has_many :organizations,
    through: :organization_members,
    uniq: true
  accepts_nested_attributes_for :authentications

  has_one :facebook_authentication, :class_name => 'Authentication', :conditions => {:provider => 'facebook'}, :dependent => :destroy

  has_many :content_items_people
  has_many :content_items, :through => :content_items_people, :foreign_key => 'person_id', :dependent => :restrict
  has_many :authored_content_items, :class_name => 'ContentItem', :foreign_key => 'person_id', :dependent => :restrict
  has_many :content_templates, :foreign_key => 'person_id', :dependent => :restrict
  has_many :contributions, :foreign_key => 'owner', :uniq => true, :dependent => :restrict
  has_many :managed_issue_pages, :foreign_key => 'person_id', :dependent => :restrict
  has_many :rating_groups, :dependent => :restrict
  has_many :subscriptions, :dependent => :destroy
  has_many :survey_responses
  has_one :organization_detail

  has_many :contributed_conversations, :through => :contributions, :source => :conversation, :uniq => true, :dependent => :restrict
  has_many :contributed_issues, :through => :contributions, :source => :issue, :uniq => true, :dependent => :restrict

  has_many :petition_signatures, :dependent => :destroy
  has_many :signed_petitions, :class_name => 'Petition', :through => :petition_signatures, :source => :petition

  validates_length_of :email, :within => 6..255, :too_long => "please use a shorter email address", :too_short => "please use a longer email address"

  validates_presence_of :zip_code, :message => ' please enter zipcode'
  validates_length_of :zip_code, :message => ' must be 5 characters or higher', :within => (5..10), :allow_blank => false, :allow_nil => false
  validates_presence_of :first_name, :last_name, :if => Proc.new{|record| record.type != 'Organization'}
  validate :check_twitter_username_format

  friendly_id :name, :use => :slugged
  def should_generate_new_friendly_id?
    new_record? || slug.nil?
  end

  def participated_actions
    # To do: need to merge this array with vote when we integrate them with vote
    self.signed_petitions.collect(&:action).compact.uniq
  end

  def participated_actions_for_conversation(conversation)
    participated_actions.delete_if{|action|action.conversation_id != conversation.id}
  end

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
                                    :content_type => /image\/*/,
                                    :message => "Not a valid image file."
  process_in_background :avatar

  scope :participants_of_issue, lambda{ |issue|
      joins(:conversations => :issues).where(['issue_id = ?',issue.id]).select('DISTINCT(people.id),people.*') if issue
    }

  scope :real_accounts, where("proxy is not true")
  scope :proxy_accounts, where(:proxy => true)
  scope :confirmed_accounts, where("confirmed_at is not null")
  scope :unconfirmed_accounts, where(:confirmed_at => nil)
  scope :only_people, where(:type => nil)
  scope :only_organizations, where(:type => 'Organization')

  delegate :conversations, :to => :subscriptions, :prefix => true
  delegate :issues,        :to => :subscriptions, :prefix => true
  delegate :organizations, :to => :subscriptions, :prefix => true

  # All these emails could be moved to an observer - Jerry
  after_create :notify_civic_commons
  before_save :check_to_send_welcome_email
  after_save :send_welcome_email, :if => :send_welcome?
  around_save :update_newsletter_subscription

  around_update :check_to_notify_email_change, :if => :send_email_change_notification?

  def send_email_change_notification?
    @send_email_change_notification || false
  end

  def check_to_notify_email_change
    old_email, new_email = self.email_change
    yield
    Notifier.email_changed(old_email, new_email).deliver if old_email && new_email
  end

  def send_confirmation_instructions
    # if spam don't send confirmation
    SpamService.spam?(email) ? false : super
  end

  def newly_confirmed?
    confirmed_at_changed? && confirmed_at_was.blank? && !confirmed_at.blank?
  end
  def subscribed_to? mailing_type
    send(mailing_type)
  end

  def check_to_send_welcome_email
    @send_welcome = true if newly_confirmed?
  end

  def create_from_auth?
    @create_from_auth || false
  end

  def display_name
    self.last_name.blank? || self.first_name.blank? ? self.name : "#{self.last_name}, #{self.first_name}"
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

  def locked?
    not self.locked_at.nil?
  end

  def require_zip_code?
    @require_zip_code || false
  end

  def name=(value)
    @name = value
    self.first_name, self.last_name = self.class.parse_name(value)
  end

  def name
    @name ||= ("%s %s" % [self.first_name, self.last_name]).strip
  end

  def on_facebook_auth?
    create_from_auth? || facebook_unlinking?
  end

  def notify_civic_commons
    Notifier.new_registration_notification(self).deliver
  end

  def send_welcome?
    @send_welcome
  end

  def send_welcome_email
    Notifier.welcome(self).deliver
    @send_welcome = false
  end

  def short_name
    self.first_name.blank? ? self.name : self.first_name
  end

  # A valid zip code is composed of:
  # * base, and
  # * optionally the extension
  #
  # Typical Format: 12345-1234
  def base_zip_code
    zip_code.respond_to?(:to_s) ? zip_code.to_s.gsub(/\-.*/, '') : ''
  end

  # Short zip code is the base zip code unless it is too short or long, then it is blank
  def short_zip_code
    short_zip = base_zip_code
    if short_zip.size < 4 or short_zip.size > 5
      ''
    else
      short_zip
    end
  end

  def most_recent_activity
    Activity.most_recent_activity_items_for_person(self)
  end

  def self.find_all_by_name(name)
    first, last = parse_name(name)
    where(:first_name => first, :last_name => last)
  end

  def self.find_confirmed_order_by_recency(person_ids=nil)
    person = Person.order('confirmed_at DESC').where('confirmed_at IS NOT NULL').where('locked_at IS NULL')
    if not person_ids.nil?
      person = person.where('confirmed_at IS NOT NULL')
      person = person.where('locked_at IS NULL')
      person = person.where({ 'people.id' => person_ids})
    end
    return person
  end

  def self.find_confirmed_order_by_most_active(person_ids=nil)
    person = Person.select("people.*, count(ti.person_id)").
      joins('left outer join top_items ti on people.id = ti.person_id').
      group('people.id').
      order('count(ti.person_id) DESC').
      where('confirmed_at IS NOT NULL AND locked_at IS NULL')
    if not person_ids.nil?
      person = person.where("confirmed_at IS NOT NULL AND locked_at IS NULL")
      person = person.where({ 'people.id' => person_ids})
    end
    return person
  end

  def self.find_confirmed_order_by_last_name(letter = nil, person_ids=nil)
    person = Person
    if not person_ids.nil?
      person = person.where({ 'people.id' => person_ids})
    end

    if letter.nil?
      person = person.order('blank_last_name, last_name, first_name ASC').
        where('confirmed_at IS NOT NULL and locked_at IS NULL').
        select("*, IF(last_name IS NULL OR last_name='' OR UCASE(SUBSTR(last_name, 1) NOT BETWEEN 'A' AND 'Z'), 1, 0) as blank_last_name")
    else
      person = person.order('last_name, first_name ASC').
        where('confirmed_at IS NOT NULL').
        where("last_name like '#{letter}%'").
        where('locked_at IS NULL')
    end
    return person
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

  def update_newsletter_subscription
    # store if it's a new record before save since *_changed? only works with existing models
    new_record = new_record?

    yield

    if new_record or weekly_newsletter_changed?
      if weekly_newsletter
        add_newsletter_subscription
      else
        remove_newsletter_subscription
      end
    end
  end

  def avatar_path(style='')
    self.avatar.path(style)
  end

  # https://graph.facebook.com/#{uid}/picture
  # optional params: type=small|square|large
  # square (50x50), small (50 pixels wide, variable height), and large (about 200 pixels wide, variable height):
  def facebook_profile_pic_url(type = :square)
    "https://graph.facebook.com/#{facebook_authentication.uid}/picture?type=#{type}" if facebook_authenticated?
  end

  def allow_facebook_connect?
    # override this in the subclass
    true
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
      AvatarService.update_avatar_url_for(self)
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


  # Avatar Image Cache
  # The cached avatar image url as determined by the AvatarService.
  def avatar_image_url
    if self.avatar_cached_image_url.blank?
      self.avatar_cached_image_url = AvatarService.avatar_image_url(self)
      save!
    end
    self.avatar_cached_image_url
  end


  # Overiding Devise::Models::DatabaseAuthenticatable
  # due to needing to set encrypted_password to blank, so that it doesn't error out when it is set to nil
  def valid_password?(password)
    encrypted_password.blank? ? false : super
  end

  def self.build_from_auth_hash(auth_hash)
    new_person = new(:name => auth_hash['info']['name'],
        :email => Authentication.email_from_auth_hash(auth_hash),
        :encrypted_password => '',
        :create_from_auth => true
      )
    new_person.authentications << Authentication.new_from_auth_hash(auth_hash)
    new_person
  end

  # overriding devise's recoverable
  def self.send_reset_password_instructions(attributes={})
    recoverable = find_or_initialize_with_errors(authentication_keys, attributes, :not_found)
    recoverable.send_reset_password_instructions if recoverable.persisted? && !recoverable.facebook_authenticated?
    recoverable
  end

  def subscribed_conversations
    subscriptions_conversations.order('created_at desc')
  end

  def subscribed_issues
    subscriptions_issues.order('created_at desc')
  end

  def subscribed_organizations
    subscriptions_organizations.order('created_at desc')
  end

  def has_website?
    attribute_present? :website
  end

  def has_twitter?
    attribute_present? :twitter_username
  end

  def has_email?
    attribute_present? :email
  end

  def is_organization?
    is_a? Organization
  end

protected
  def check_twitter_username_format
    match = /^@?(?<username>.*)$/.match(self.twitter_username)
    self.twitter_username = match[:username] unless match.nil?
  end

  def password_required?
    if facebook_authenticated?
      facebook_unlinking? ? true : false
    else
      (!persisted? && !create_from_auth?) || password.present? || password_confirmation.present?
    end
  end

  def add_newsletter_subscription
    if Civiccommons::Config.mailer['mailchimp']
      merge_tags = { :FNAME => first_name, :LNAME => last_name, :ZIP => short_zip_code }
      merge_tags = merge_tags.each{|key, value| merge_tags[key] = '' if value.nil? }

      Delayed::Job.enqueue Jobs::SubscribeToEmailListJob.new(
        Civiccommons::Config.mailer['api_token'],
        Civiccommons::Config.mailer['weekly_newsletter_list_id'],
        email,
        merge_tags)
    end
  end

  def remove_newsletter_subscription
    if Civiccommons::Config.mailer['mailchimp']
      Delayed::Job.enqueue Jobs::UnsubscribeFromEmailListJob.new(
        Civiccommons::Config.mailer['api_token'],
        Civiccommons::Config.mailer['weekly_newsletter_list_id'],
        email)
    end
  end

end
