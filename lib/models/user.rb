require 'uuid'

class User < ActiveRecord::Base
  has_many :emails
  before_save :make_incoming_key
  
  def make_incoming_key
    write_attribute(:incoming_key,UUID.new.generate.gsub('-',''))
  end
end