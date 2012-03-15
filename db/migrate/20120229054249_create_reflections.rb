class CreateReflections < ActiveRecord::Migration
  def self.up
    create_table :reflections do |t|
      t.string :title, :null => false
      t.text :details, :null => false

      t.integer :owner, :null => false
      t.integer :conversation_id, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :reflections
  end
end
