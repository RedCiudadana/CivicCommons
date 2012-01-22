class ContentItem < ActiveRecord::Base
  
  attr_accessor :url_slug

  CONTENT_TYPES = ["BlogPost", "NewsItem", "RadioShow"]

  searchable :include => [:author, :conversation], :ignore_attribute_changes_of => [ :updated_at ] do
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
  belongs_to :conversation
  has_and_belongs_to_many :topics, uniq: true
  
  # Any radioshow people
  has_and_belongs_to_many :people, 
                          :readonly => true,
                          :uniq => true,
                          :class_name => 'Person',
                          :join_table => 'content_items_people'
  
  #radioshow hosts
  has_and_belongs_to_many :hosts, 
                          :uniq => true,
                          :class_name => 'Person',
                          :join_table => 'content_items_people',
                          :conditions => {:content_items_people => {:role => 'Host'}},
                          :insert_sql => 'INSERT INTO `content_items_people` (`content_item_id`, `person_id`, `role`,`created_at`,`updated_at`) VALUES (#{id}, #{record.id}, "Host","#{created_at}","#{updated_at}")',
                          :delete_sql => 'DELETE FROM `content_items_people` WHERE `content_items_people`.`content_item_id` = #{id} AND `content_items_people`.`person_id` IN (#{record.id}) AND `content_items_people`.`role` = "Host"'
  #radioshow guests
  has_and_belongs_to_many :guests, 
                          :uniq => true,
                          :class_name => 'Person',
                          :join_table => 'content_items_people',
                          :conditions => {:content_items_people => {:role => 'Guest'}},
                          :insert_sql => 'INSERT INTO `content_items_people` (`content_item_id`, `person_id`, `role`,`created_at`,`updated_at`) VALUES (#{id}, #{record.id}, "Guest","#{created_at}","#{updated_at}")',
                          :delete_sql => 'DELETE FROM `content_items_people` WHERE `content_items_people`.`content_item_id` = #{id} AND `content_items_people`.`person_id` IN (#{record.id}) AND `content_items_people`.`role` = "Guest"'


  delegate   :name, :to => :author, :prefix => true

  validates_presence_of :title, :body, :author
  validates_uniqueness_of :title
  validate :require_topic

  validates_format_of :external_link, :with => /^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?$/ix, :allow_blank => true
  validates_presence_of :external_link, :if => :content_type_is_news_item?
  
  validates :published, :date => {:after => Proc.new {Time.now - 1.year} }

  has_friendly_id :title, :use_slug => true, :strip_non_ascii => true
  
  def people=(record)
    raise Exception, ":people is readonly. please use :hosts or :guests habtm association, instead!"
  end
  
  def has_topic?(topic)
    topics.include?(topic)
  end
  
  def require_topic
    errors.add(:base, "Please select at least one Topic") if self.topic_ids.blank?
  end
  
  def self.recent_blog_posts(author = nil)
    if author.nil?
      ContentItem.where("content_type = 'BlogPost' AND (published <= curdate() OR DAY(published) = DAY(curdate())) ").order("published desc, created_at desc")
    else
      author = author.id if author.is_a? Person
      ContentItem.where(person_id: author).where("content_type = 'BlogPost' AND (published <= curdate() OR DAY(published) = DAY(curdate())) ").order("published desc, created_at desc")
    end
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
      self.guests << person
      return true
    when 'host'
      self.hosts << person
      return true
    else
      return false
    end
  end
  
  def delete_person(role, person)
    case role
    when 'guest'
      self.guests.delete(person)
      return true
    when 'host'
      self.hosts.delete(person)
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
end
