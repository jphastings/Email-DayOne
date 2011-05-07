require 'sinatra'
require File.join(File.dirname(__FILE__), 'environment')
require File.join(File.dirname(__FILE__), 'lib','helpers')
require 'dropbox'
require 'sinatra/session'

helpers do
  def prep_dropbox
    if session[:dropbox_session]
      @dropbox = Dropbox::Session.deserialize(session[:dropbox_session])
    else
      @dropbox = Dropbox::Session.new(ENV['DROPBOX_KEY'], ENV['DROPBOX_SECRET'])
      session[:dropbox_session] = @dropbox.serialize
    end
    
    @dropbox.mode = :dropbox
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

get '/delete' do
  prep_dropbox
  redirect('/') unless @dropbox.authorized?
  
  User.find_by_dropbox_id(@dropbox.account.uid).destroy
  
  session_end!
  
  haml :deleted
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
    @user = User.find_by_dropbox_id(@dropbox.account.uid)
  rescue NoMethodError
    
    begin
      @user = User.create(
        :dropbox_session => @dropbox.serialize,
        :dropbox_id => @dropbox.account.uid,
        :journal_location => scan_for_journal('/',5)
      )
    rescue NoJournalError
      halt(400,haml(:nojournal))
    end
    @user.emails << Email.create(:email => @dropbox.account.email)
    
    @user.save
  end
  
  case params['action']
  when 'add'
    Email.find_or_create_by_email_and_user_id(params['email'],@user.id)
  when 'remove'
    Email.find(:first,:conditions => ['email = ? and user_id = ?',params['email'],@user.id]).each {|e| e.destroy}
  end
  
  haml :settings
end

post '/receive_emails' do
  begin
    to_user = User.find_by_incoming_key(params['to'].gsub(/@.*$/,''))
    raise NoSuchUserError if to_user.nil?
    
    from_email = Email.find_by_email(params['from'].gsub(/^.*\<(.+)\>$/,'\\1'))
    raise NoSuchEmailError if from_email.nil?
    from_user = from_email.user
    raise MismatchUserError unless to_user == from_user
    user = to_user
    $stdout.puts "Email received from user ##{to_user.id}"
    
    # TODO: Log in
    @dropbox = Dropbox::Session.deserialize(to_user.dropbox_session)
    @dropbox.mode = :dropbox
    
    entries = @dropbox.directory(File.join(user.journal_location,'entries'))
    
    # This will throw an error if the folder doesn't exist
    entries.metadata
  
    require File.join(File.dirname(__FILE__), 'lib','dayone')
    require 'stringio'
    
    entry = DayOne.new(
      :creation_date => (Time.parse(params['headers'].match(/^Date: (.*)$/)[1]) rescue Time.now),
      :entry_text => params['text'] || params['html'],
      :starred => (not params['headers'].match(/^X-Priority: 1$/).nil?),
      :tags => params['subject'].split(/\ +/)
    )
    
    @dropbox.upload(StringIO.new(entry.to_plist),File.join(user.journal_location,'entries'), :as => File.join(user.journal_location,'entries',entry.uuid+'.doentry'))
    
    $stdout.puts "Entry from #{from_email.email} successfully added to their Dropbox"
    halt(200)
  rescue NoSuchUserError,NoSuchEmailError,MismatchUserError
    halt(403,"You are not authorized to use this service")
  rescue Dropbox::FileNotFoundError
    halt(400,"We couldn't find your journal file! Are you sure it's in your dropbox as /Journal.dayone?")
  end
end