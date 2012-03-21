class MyDropbox
  include Mongoid::Document
  include Mongoid::Timestamps

  referenced_in :user
  
  field :session, :type => String, :default => ""
  
  def new_session
    session = ""
    unless self.session.empty?
      session = DropboxSession.deserialize(self.session)
    else
      session = DropboxSession.new(Dropbox::APP_KEY, Dropbox::APP_SECRET)
    end
    session.get_request_token
    self.session = session.serialize
    self.save
    session
  end
  
  def get_access_token
    unless self.session.empty?
      session = DropboxSession.deserialize(self.session)
      session.get_access_token
      self.session = session.serialize
      self.save
      true
    else
      false
    end
  end
  
  def get_authorize_url callback=""
    session = ""
    if self.session.empty?
      session = new_session
    else
      session = DropboxSession.deserialize(self.session)
    end
    if callback.empty?
      session.get_authorize_url
    else
      session.get_authorize_url callback
    end
  end
  
  def reset_session
    self.session = ""
    self.save
  end
  
  def deliver filename, delivery_path
    if temp_session = new_session
      if temp_session.authorized?
        client = DropboxClient.new(temp_session, Dropbox::ACCESS_TYPE)
        client.file_delete "#{delivery_path}#{filename}" rescue nil
        client.put_file "#{delivery_path}#{filename}", open(filename) rescue nil
      end
    end
  end
end
