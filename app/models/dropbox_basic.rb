# -*- encoding : UTF-8 -*-
class DropboxBasic
  include Mongoid::Document
  include Mongoid::Timestamps

  referenced_in :external_file_storage
  
  field :session, type: String, default: ''
  field :path,    type: String, default: ':code/:year:month/:account_book/'
  
  def new_session
    current_session = ''
    if self.session.present?
      current_session = DropboxSession.deserialize(self.session)
    else
      current_session = DropboxSession.new(Dropbox::APP_KEY, Dropbox::APP_SECRET)
    end
    current_session.get_request_token
    update_attribute(:session, current_session.serialize)
    current_session
  end
  
  def get_access_token
    if self.session.present?
      current_session = DropboxSession.deserialize(self.session)
      current_session.get_access_token
      update_attribute(:session, current_session.serialize)
    else
      false
    end
  end
  
  def get_authorize_url(callback='')
    current_session = ''
    if self.session.empty?
      current_session = new_session
    else
      current_session = DropboxSession.deserialize(self.session)
    end
    if callback.empty?
      current_session.get_authorize_url
    else
      current_session.get_authorize_url(callback)
    end
  end
  
  def is_configured?
    new_session.authorized?
  end
  
  def reset_session
    self.session = ''
    self.save
  end
  
  def is_updated(path, filename, client)
    begin
      result = client.metadata("#{path}/#{filename}")
    rescue DropboxError
      result = nil
    end
    if result
      size = result["bytes"]
      if size == File.size(filename)
        true
      else
        false
      end
    else
      false
    end
  end
  
  def is_not_updated(path, filename, client)
    !is_updated(path, filename, client)
  end
  
  def deliver filespath, folder_path
    @temp_session ||= new_session
    if @temp_session.try(:authorized?)
      @client ||= DropboxClient.new(@temp_session, Dropbox::ACCESS_TYPE)
      clean_path = folder_path.sub(/\/$/,"")
      filespath.each do |filepath|
        filename = File.basename(filepath)
        if is_not_updated(clean_path, filename, @client)
          @client.file_delete "#{clean_path}/#{filename}" rescue nil
          @client.put_file "#{clean_path}/#{filename}", open(filepath)
        end
      end
    end
  end
end
