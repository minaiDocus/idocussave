# -*- encoding : UTF-8 -*-
class DropboxBasic
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :external_file_storage
  
  field :session,              type: String,  default: ''
  field :path,                 type: String,  default: ':code/:year:month/:account_book/'
  field :file_type_to_deliver, type: Integer, default: ExternalFileStorage::PDF

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

  def is_up_to_date(remote_filepath, filepath)
    path = File.dirname(remote_filepath)
    filename = File.basename(remote_filepath)
    results = client.search(path, filename, 1)
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

  def is_not_up_to_date(remote_filepath, filepath)
    !is_up_to_date(remote_filepath, filepath)
  end

  def sync(remote_files)
    remote_files.each_with_index do |remote_file,index|
      remote_path = ExternalFileStorage::delivery_path(remote_file, self.path)
      remote_filepath = File.join(remote_path, remote_file.name)
      tries = 0
      begin
        remote_file.sending!(remote_filepath)
        print "\t[#{'%0.3d' % (index+1)}] \"#{remote_filepath}\" "
        if is_not_up_to_date(remote_filepath, remote_file.local_path)
          print "sending..."
          client.put_file("#{remote_filepath}", open(remote_file.local_path), true)
          print "done\n"
        else
          print "is up to date\n"
        end
        remote_file.synced!
      rescue => e
        tries += 1
        print "failed : [#{e.class}] #{e.message}\n"
        if tries < 3
          retry
        else
          puts "\t[#{'%0.3d' % (index+1)}] Retrying later"
          remote_file.not_synced!("[#{e.class}] #{e.message}")
        end
      end
    end
  end
end
