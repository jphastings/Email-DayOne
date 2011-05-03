require 'sinatra'
require File.join(File.dirname(__FILE__), 'environment')
require 'dropbox'
require 'sinatra/session'

set :port, 4568

helpers do
  def prep_dropbox
    if session[:dropbox_session]
      @dropbox = Dropbox::Session.deserialize(session[:dropbox_session])
    else
      @dropbox = Dropbox::Session.new(ENV['DROPBOX_KEY'], ENV['DROPBOX_SECRET'])
      session[:dropbox_session] = @dropbox.serialize
    end
    
    @dropbox.mode = :dropbox
    redirect('/settings') if @dropbox.authorized? and env['REQUEST_URI'] != '/settings'
  end
end

get '/' do
  prep_dropbox  
  haml :index
end

get '/login' do
  session_end!
  prep_dropbox
  redirect @dropbox.authorize_url(:oauth_callback => "http://#{env['HTTP_HOST']}/auth")
end

get '/logout' do
  session_end!
  redirect '/'
end

get '/auth' do
  prep_dropbox
  
  begin
    @dropbox.authorize
    
    session[:dropbox_session] = @dropbox.serialize
    
    redirect '/settings'
  rescue OAuth::Unauthorized
    # TODO: flash - bad login
    redirect '/'
  end
end

get '/settings' do
  prep_dropbox
  redirect('/') unless @dropbox.authorized?
  begin
    @user = Email.find_by_email(@dropbox.account.email).user
  rescue NoMethodError
    @user = User.create(
      :dropbox_session => @dropbox.serialize,
    )
    @user.emails << Email.create(:email => @dropbox.account.email)
    
    @user.save
  end
  haml :settings
end

post '/receive_emails' do
  p params
  to_user = User.find_by_incoming_key(params['key'].gsub(/@.*$/,''))
  from_user = Email.find_by_email(params['from']).user
  unless to_user == from_user
    # TODO: dodgey incoming, write to logs?
    halt(200)
  end
  
  # TODO: Log in
  
  # TODO: can find journal?
  
  require File.join(File.dirname(__FILE__), 'lib','dayone')
  
  entry = DayOne.new(
    #:creation_date => params['headers']?
    :creation_date => Time.now,
    :entry_text => params['text'] || params['html'],
    #:starred => params['headers'] high priority?
    :starred => false
  )
  
  puts entry.to_plist
  halt(200)
end