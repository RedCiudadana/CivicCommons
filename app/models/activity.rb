class Activity < ActiveRecord::Base

  set_table_name "top_items"

  belongs_to :item, polymorphic: true
  belongs_to :person

  validates :item_id, presence: true
  validates :item_type, presence: true
  validates :item_created_at, presence: true
  validates :person_id, presence: true

  VALID_TYPES = [ Conversation, Contribution, Issue, RatingGroup, SurveyResponse ]

  # Accept an Active Record object of valid type
  def initialize(attributes = nil)

    if Activity.valid_type?(attributes)
      attributes = attributes.becomes(Contribution) if attributes.is_a?(Contribution)
      attr = {
        item_id: attributes.id,
        item_type: attributes.class.to_s,
        item_created_at: attributes.created_at,
        person_id: attributes.person.id
      }
      if attributes.respond_to?(:conversation_id) && !attributes.conversation_id.nil?
        attr[:conversation_id] = attributes.conversation_id
        attr[:activity_cache] = Activity.encode(attributes)
      elsif attributes.respond_to?(:issue_id) && !attributes.issue_id.nil?
        attr[:issue_id] = attributes.issue_id
        attr[:activity_cache] = Activity.encode(attributes)
      elsif attributes.is_a?(Conversation)
        attr[:conversation_id] = attributes.id
        attr[:activity_cache] = Activity.encode(attributes)
      end

      attributes = attr
    end

    super(attributes)
  end

  ############################################################
  # class utility methods
  ############################################################

  # Update cache data
  def self.update(model)
    model = model.becomes(Contribution) if model.is_a?(Contribution)

    if Activity.valid_type?(model)
      item = Activity.where(item_id: model.id, item_type: model.class.to_s).first
      unless item.nil?
        item.activity_cache = Activity.encode(model)
        item.save
      end
    end
  end

  # Accept an Active Record object of valid type
  def self.delete(model)
    if Activity.valid_type?(model)
      model = model.becomes(Contribution) if model.is_a?(Contribution)
      Activity.delete_all("item_id = #{model.id} and item_type like '#{model.class}'")
    else
      super(model)
    end
  end

  # Accept an Active Record object of valid type
  def self.destroy(model)
    if Activity.valid_type?(model)
      model = model.becomes(Contribution) if model.is_a?(Contribution)
      Activity.destroy_all("item_id = #{model.id} and item_type like '#{model.class}'")
    else
      super(model)
    end
  end

  # Find if the activity exists for an Active Record object.
  def self.exists?(model)
    if Activity.valid_type?(model)
      model = model.becomes(Contribution) if model.is_a?(Contribution)
      Activity.exists?(:item_id => model.id, :item_type=> model.class)
    else
      super(model)
    end
  end

  # Check if item is a valid type for Activity
  def self.valid_type?(item)
    ok = false
    VALID_TYPES.each do |type|
      if (item.is_a? Contribution and not item.top_level_contribution?)
        ok = true
        break
      elsif item.is_a? type and not item.is_a? Contribution
        ok = true
        break
      elsif item.is_a? GenericObject and item.__class__ == 'Contribution' and not item.top_level_contribution?
        ok = true
        break
      elsif item.is_a? GenericObject and item.__class__ == type.to_s and not item.__class__ == 'Contribution'
        ok = true
        break
      end
    end
    return ok
  end

  def self.encode(item)
    obj = nil
    if Activity.valid_type?(item)
      if item.is_a? Conversation
        obj = ActiveSupport::JSON.encode(item, include: [:person])
      elsif item.is_a? Contribution
        obj = ActiveSupport::JSON.encode(item, include: [:person, :conversation])
      elsif item.is_a? RatingGroup
        # need to load rating descriptors
        obj = ActiveSupport::JSON.encode(item, include: [:person, :ratings, :conversation, :contribution])
      elsif item.is_a? SurveyResponse
        obj = ActiveSupport::JSON.encode(item, include: {person:{}, survey: {methods: :type}}) #included the STI type on surveys
      end
    end
    return obj
  end

  def self.decode(item)
    hash = ActiveSupport::JSON.decode(item)
    return self.to_active_record(hash.keys.first, hash.values.first)
  end

  ############################################################
  # custom finders

  # Retrieves the most recent activity items
  #
  # If any of the items do not exist, they will not be returned. Hence
  # it is possible to get less than the requested amount of activity
  # items.
  def self.most_recent_activity_items(limit = nil)
    activities = Activity.order('item_created_at DESC')
    activities = activities.limit(limit) if limit
    activities.collect{|a| a.item}.compact
  end

  def self.most_recent_activity_items_for_issue(issue, limit = nil)
    activities = Activity.where(issue_id: issue.id).order('item_created_at DESC')
    activities = activities.limit(limit) if limit
    activities.collect{|a| a.item}.compact
  end

  def self.most_recent_activity_items_for_conversation(conversation, limit = nil, offset = 0)
    activities = Activity.where(conversation_id: conversation.id).order('item_created_at DESC')
    activities = activities.offset(offset) if offset.present?
    activities = activities.limit(limit) if limit
    activities.collect{|a| a.item}.compact
  end
  
  def self.most_recent_activity_items_for_conversations(conversation_ids=[], limit = nil)
    activities = Activity.where(conversation_id: conversation_ids).order('item_created_at DESC')
    activities = activities.limit(limit) if limit
    activities.collect{|a| a.item}.compact
  end

  def self.most_recent_activity_items_for_person(person, limit = nil)
    activities = Activity.where(person_id: person.id).order('item_created_at DESC')
    activities = activities.limit(limit) if limit
    activities.collect{|a| a.item}.compact
  end

  private

  ############################################################
  # encode/decode helpers

  def self.to_active_record(clazz, data)
    clazz = clazz.classify.constantize
    data.each do |key, value|
      if value.is_a? Hash
        data[key] = self.to_active_record(key, value)
      elsif value.is_a? Array
        value.each_with_index do |data, index|
          value[index] = self.to_active_record(key, data) if value[index].is_a? Hash
        end
      end
    end
    data['__class__'] = clazz.to_s
    obj = GenericObject.new(data)
    return obj
  end

end
