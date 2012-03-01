class Opportunity < ActiveRecord::Base
	has_one :conversation, :dependent => :destroy
	has_friendly_id :title, :use_slug => true, :strip_non_ascii => true

  delegate :cached_slug, to: :conversation
  delegate :image, to: :conversation
  delegate :participants, to: :conversation
  delegate :summary, to: :conversation
  delegate :title, to: :conversation

  def self.available_filters
    {
      :recommended => :recommended,
      :active => :most_active,
      :popular => :top_visited,
      :recent => :latest_created
    }
  end

  def self.filtered(filter)
    self.send(available_filters[filter.to_sym])
  end

  def self.latest_created
    Opportunity.joins(:conversation).
      where('conversations.exclude_from_most_recent = false').
      order('conversations.created_at DESC')
  end

  def self.most_active
    Opportunity.joins(:conversation => :contributions).
      select('opportunities.id, COUNT(*) AS count_all, MAX(contributions.created_at) AS max_contributions_created_at').
      where('contributions.top_level_contribution = 0').
      where('contributions.created_at > ?', Time.now - 60.days).
      group('conversations.id').
      order('count_all DESC, max_contributions_created_at DESC')
  end

  def self.recommended
    Opportunity.joins(:conversation).
      where('conversations.staff_pick = true').
      order('conversations.position ASC')
  end

  def self.top_visited
    Opportunity.joins(:conversation).
      where('conversations.last_visit_date >= ?', Time.now - 30.days).
      order('conversations.recent_visits DESC')
  end
end