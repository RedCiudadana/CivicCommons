class AddAvatarCachedImageUrlToPeople < ActiveRecord::Migration
  def self.up
    add_column :people, :avatar_cached_image_url, :string
  end

  def self.down
    remove_column :people, :avatar_cached_image_url
  end
end
