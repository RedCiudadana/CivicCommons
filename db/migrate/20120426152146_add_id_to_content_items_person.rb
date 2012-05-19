class AddIdToContentItemsPerson < ActiveRecord::Migration
  def self.up
    add_column :content_items_people, :id, :primary_key
  end

  def self.down
    remove_column :content_items_people, :id
  end
end
