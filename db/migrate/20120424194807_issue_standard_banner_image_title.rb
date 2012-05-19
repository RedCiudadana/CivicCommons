class IssueStandardBannerImageTitle < ActiveRecord::Migration
  def self.up
    add_column :issues, :standard_banner_image_title, :string
  end

  def self.down
    remove_column :issues, :standard_banner_image_title
  end
end