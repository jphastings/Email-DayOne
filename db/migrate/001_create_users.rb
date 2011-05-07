class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |table|
      table.text      :dropbox_session, :default => nil
      table.string    :incoming_key
      table.text      :journal_location, :default => '/Journal.dayone'
      table.integer   :dropbox_id
      
      table.timestamp :created_on
    end
  end
  
  def self.down
    drop_table :users
  end
end