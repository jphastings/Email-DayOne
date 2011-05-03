require File.join(File.dirname(__FILE__), 'app')

set :run, false
set :environment, :development

run Sinatra::Application
