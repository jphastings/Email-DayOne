class CreateEmails < ActiveRecord::Migration
  def self.up
    create_table :emails do |table|
      table.integer   :user_id
      table.string    :email
      
      table.timestamp :created_on
    end
  end
  
  def self.down
    drop_table :emails
  end
end