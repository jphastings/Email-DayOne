require 'uuid'

class Email < ActiveRecord::Base
  belongs_to :user
end

class User < ActiveRecord::Base
  has_many :emails, :dependent => :destroy
  before_save :make_incoming_key
  
  def make_incoming_key
    write_attribute(:incoming_key,UUID.new.generate.gsub('-',''))
  end
end