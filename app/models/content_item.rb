class ContentItem < ActiveRecord::Base
  extend FriendlyId

  attr_accessor :url_slug

  CONTENT_TYPES = ["BlogPost", "NewsItem", "RadioShow"]

  searchable :include => [:author, :conversations], :ignore_attribute_changes_of => [ :updated_at ] do
    text :title, :boost => 2, :default_boost => 2
    text :body, :stored => true do
      Sanitize.clean(body, :remove_contents => ['style','script'])
    end
    text :summary, :stored => true do
      Sanitize.clean(summary, :remove_contents => ['style','script'])
    end
    string :content_type
  end

  scope :blog_post, where(:content_type => 'BlogPost')
  scope :radio_show, where(:content_type => 'RadioShow' )
  scope :news_item, where(:content_type => 'NewsItem')
  scope :newer_than, lambda {|date| where(['published >= ?',date.to_s(:db)])}
  scope :recent_blog_posts, lambda { |author = nil|
    if author.nil?
      return where("content_type = 'BlogPost' AND (published <= curdate() OR DAY(published) = DAY(curdate())) ").order("published desc, created_at desc")
    else
      author = author.id if author.is_a? Person
      return where(person_id: author).where("content_type = 'BlogPost' AND (published <= curdate() OR DAY(published) = DAY(curdate())) ").order("published desc, created_at desc")
    end
  }

  has_attached_file :image,
    :styles => {
      :normal => "480x300#",
      :panel => "198x130#"
    },
    :storage => :s3,
    :s3_credentials => S3Config.credential_file,
    :path => IMAGE_ATTACHMENT_PATH,
    :default_url => '/images/convo_img_:style.gif'

  validates_attachment_content_type :image,
                                    :content_type => /image\/*/,
                                    :message => "Not a valid image file."

  belongs_to :author, :class_name => "Person", :foreign_key => "person_id"

  has_many :content_items_topics, :uniq => true
  has_many :topics, :through => :content_items_topics, uniq: true

  has_many :content_items_conversations, :uniq => true
  has_many :conversations, :through => :content_items_conversations, uniq: true

  has_many :links, :class_name => 'ContentItemLink', :dependent => :destroy

  has_many :content_items_people, uniq: true

  # Any radioshow people
  has_many :people,
    :through => :content_items_people,
    :readonly => true,
    :uniq => true,
    :class_name => 'Person'

  #radioshow hosts 
  # creating or deleting this doesn't work as it should, there's an open issue https://github.com/rails/rails/issues/5057
  # use add_person method, or delete_person method, instead of content_item.hosts = [@person] and content_item.hosts.delete(@person)
  has_many :hosts,
    :through => :content_items_people,
    :uniq => true,
    :class_name => 'Person',
    :conditions => {:content_items_people => {:role => 'Host'}},
    :source => :person

  #radioshow guests
  # creating or deleting this doesn't work as it should, there's an open issue https://github.com/rails/rails/issues/5057
  # use add_person method, or delete_person method, instead of content_item.guests = [@person] and content_item.guests.delete(@person)
  has_many :guests,
    :through => :content_items_people,
    :uniq => true,
    :class_name => 'Person',
    :conditions => {:content_items_people => {:role => 'Guest'}},
    :source => :person

  delegate   :name, :to => :author, :prefix => true

  validates_presence_of :title, :body, :author
  validates_uniqueness_of :title
  validate :require_topic

  validates_format_of :external_link, :with => /^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?$/ix, :allow_blank => true
  validates_presence_of :external_link, :if => :content_type_is_news_item?

  validates_presence_of :published

  friendly_id :title, :use => :slugged
  def should_generate_new_friendly_id?
    new_record? || slug.nil?
  end

  def people=(record)
    raise Exception, ":people is readonly. please use :hosts or :guests habtm association, instead!"
  end

  def has_topic?(topic)
    topics.include?(topic)
  end

  def require_topic
    errors.add(:base, "Please select at least one Topic") if self.topic_ids.blank?
  end

  def link_title(title=nil)
    if title.nil?
      title = "Listen to the podcast..." if self.content_type_is_radio_show?
      title = "Continue reading..." if self.content_type_is_blog_post? || title.nil?
    end

    self.link_text.blank? ? title : self.link_text
  end

  def self.recent_radio_shows
    ContentItem.where('content_type = ?', 'RadioShow').order("published desc, created_at desc")
  end

  def url
    return blog_path(self) if self.content_type == 'BlogPost'
    return self.external_link if self.content_type == 'NewsItem'
    return radioshow_path(self) if self.content_type == 'RadioShow'
    return content_path(self)
  end

  def add_person(role, person)
    case role
    when 'guest'
      self.content_items_people << ContentItemsPerson.create(role: 'Guest', person: person, content_item: self)
      return true
    when 'host'
      self.content_items_people << ContentItemsPerson.create(role: 'Host', person: person, content_item: self)
      return true
    else
      return false
    end
  end

  def delete_person(role, person)
    case role
    when 'guest'
      self.content_items_people.where(role: 'Guest', person_id: person.id, content_item_id: self.id).each do |content_item|
        content_item.delete
      end
      return true
    when 'host'
      self.content_items_people.where(role: 'Host', person_id: person.id, content_item_id: self.id).each do |content_item|
        content_item.delete
      end
      return true
    else
      return false
    end
  end

  def content_type_is_blog_post?
    content_type == "BlogPost"
  end

  def content_type_is_news_item?
    content_type == "NewsItem"
  end

  def content_type_is_radio_show?
    content_type == "RadioShow"
  end

  def self.blog_authors
    people_query = ContentItem.blog_post.recent_blog_posts.newer_than(3.months.ago).select('DISTINCT(person_id)')
    blog_author_ids = people_query.collect(&:person_id)
    Person.find(blog_author_ids)
  end

end
