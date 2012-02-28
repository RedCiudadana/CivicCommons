class CreateOpportunity < ActiveRecord::Migration
	def self.up
		create_table :opportunities do |t|
	   	t.timestamps
	  end
		add_column :conversations, :opportunity_id, :integer
  end

  def self.down
  	drop_table :opportunities
  	remove_column :conversations, :opportunity_id
  end
end
