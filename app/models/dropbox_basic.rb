# -*- encoding : UTF-8 -*-
class DropboxBasic
  include Mongoid::Document
  include Mongoid::Timestamps

  referenced_in :external_file_storage
  
  field :session, type: String, default: ''
  field :path,    type: String, default: ':code/:year:month/:account_book/'
  
  def new_session
    unless @current_session
      if self.session.present?
        @current_session = DropboxSession.deserialize(self.session)
      else
        @current_session = DropboxSession.new(Dropbox::APP_KEY, Dropbox::APP_SECRET)
      end
      @current_session.get_request_token
      update_attribute(:session, @current_session.serialize)
    end
    @current_session
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
    if callback.empty?
      new_session.get_authorize_url
    else
      new_session.get_authorize_url(callback)
    end
  end
  
  def is_configured?
    new_session.authorized?
  end

  def client
    if is_configured?
      @client ||= DropboxClient.new(new_session, Dropbox::ACCESS_TYPE)
    else
      nil
    end
  end

  def reset_session
    self.session = ''
    self.save
  end

  def is_up_to_date(path, filepath)
    filename = File.basename(filepath)
    begin
      results = client.search(path,filename,1)
    rescue DropboxError => e
      Delivery::Error.create(sender: 'DropboxBasic', state: 'searching', filepath: "#{File.join([path,filename])}", message: e, user_id: external_file_storage.user)
      results = []
    end
    if results.any?
      size = results.first["bytes"]
      if size == File.size(filepath)
        true
      else
        false
      end
    else
      nil
    end
  end

  def is_not_up_to_date(path, filepath)
    !is_up_to_date(path, filepath)
  end

  def deliver filespath, folder_path
    if client
      clean_path = folder_path.sub(/\/$/,"")
      filespath.each do |filepath|
        filename = File.basename(filepath)
        tries = 0
        begin
          if is_not_up_to_date(clean_path,filepath)
            print "sending #{clean_path}/#{filenam} ..."
            client.put_file("#{clean_path}/#{filename}", open(filepath), true)
            print "done\n"
          end
        rescue Timeout::Error
          tries += 1
          print "failed\n"
          puts "Trying again!"
          retry if tries <= 3
        rescue => e
          Delivery::Error.create(sender: 'DropboxBasic', state: 'sending', filepath: "#{File.join([clean_path,filename])}", message: e, user_id: external_file_storage.user)
        end
      end
    end
  end
end
