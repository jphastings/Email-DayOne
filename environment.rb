require 'active_record'
require 'haml'

require 'sinatra' unless defined?(Sinatra)

configure do
  # load models
  $LOAD_PATH.unshift("#{File.dirname(__FILE__)}/lib/models")
  Dir.glob("#{File.dirname(__FILE__)}/lib/models/*.rb") { |lib| require File.basename(lib, '.*') }
  
  ActiveRecord::Base.establish_connection(YAML::load(File.open("#{File.dirname(__FILE__)}/config/database.yml"))[ENV['ENVIRONMENT'] || 'development'])
end
