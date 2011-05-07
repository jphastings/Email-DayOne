require 'active_record'
require 'haml'

require 'sinatra' unless defined?(Sinatra)

configure do
  require File.join(File.dirname(__FILE__),'lib','models.rb')
  
  ActiveRecord::Base.establish_connection(YAML::load(File.open("#{File.dirname(__FILE__)}/config/database.yml"))[ENV['RACK_ENV'] || 'development'])
end
