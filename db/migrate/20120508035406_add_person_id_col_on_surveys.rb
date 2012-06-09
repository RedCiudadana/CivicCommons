class AddPersonIdColOnSurveys < ActiveRecord::Migration
  def self.up
    add_column :surveys, :person_id, :integer
    add_index :surveys, :person_id
  end

  def self.down
    remove_index :surveys, :person_id
    remove_column :surveys, :person_id
  end
end