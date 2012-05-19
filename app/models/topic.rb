class Topic < ActiveRecord::Base
  has_many :issues, through: :issues_topics, uniq: true
  has_many :issues_topics, uniq: true

  has_many :content_items_topics, :uniq => true

  has_many :radioshows,
    through: :content_items_topics,
    class_name: 'ContentItem',
    conditions: 'content_type = "RadioShow"',
    source: :content_item,
    uniq: true

  has_many :blogposts,
    through: :content_items_topics,
    class_name: 'ContentItem',
    conditions: 'content_type = "BlogPost"',
    source: :content_item,
    uniq: true

  validates_presence_of :name
  validates_uniqueness_of :name

  scope :including_public_issues,
    joins(:issues).
      select('topics.*,count(issues.id) AS issue_count').
      where(:issues=>{:exclude_from_result => false,:type => 'Issue'}).
      group('topics.id').having('count(issues.id) > 0')

  # Issue with conditions on joins: https://github.com/rails/rails/issues/2637
  # The conditions are incorrectly used as ON parameters for the JOIN instead of WHERE clause
  #
  # Would have rather done something like:
  #
  #   joins(:radioshows).
  #     select('topics.*, count(content_items_topics.topic_id) AS radioshow_count').
  #     group('content_items_topics.topic_id')
  #

  scope :including_public_content_items, lambda {|content_type|
    case content_type
    when :blogpost
      content_type_criteria = 'BlogPost'
    when :radioshow
      content_type_criteria = 'RadioShow'
    end
    joins('INNER JOIN `content_items_topics` ON `content_items_topics`.`topic_id` = `topics`.`id`').
      joins('INNER JOIN content_items ON content_items_topics.content_item_id = content_items.id').
      select('topics.*, count(content_items_topics.topic_id) AS content_item_count').
      where(['content_items.content_type = ?', content_type_criteria]).
      group('content_items_topics.topic_id')
  }

  scope :including_public_radioshows, lambda {
      including_public_content_items(:radioshow)
  }

  scope :including_public_blogposts, lambda {
    including_public_content_items(:blogpost)
  }

end
