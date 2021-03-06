class HomepageFeatured < ActiveRecord::Base
  belongs_to :homepage_featureable, polymorphic: true
  validates_presence_of :homepage_featureable_id, :homepage_featureable_type
  validates_uniqueness_of :homepage_featureable_id, scope: :homepage_featureable_type
  delegate :image, :title, to: :homepage_featureable

  # Returns back a minimium of the desired items that are not in the filter.
  #
  # returns back an empty array if the desired number is not available.
  def self.sample_and_filtered(limit=10, filter = [])
    filter = [filter] unless filter.respond_to?(:flatten)
    filter.flatten!

    featured = self.all
    featured = featured.select{|feature| !(([feature.homepage_featureable] - filter)).blank?}

    samples = featured.sample(limit)

    samples.collect{|sample| sample.homepage_featureable}
  end
end
