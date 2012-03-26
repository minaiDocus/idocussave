class DropboxExtended
  PATH = "#{Rails.root}/data/"
  
  class << self
    def get_session
      session = nil
      if File.exist? "#{PATH}dropbox-session.txt"
        File.open "#{PATH}dropbox-session.txt","r" do |file|
          session = DropboxSession.deserialize(file.readlines.join)
        end
      else
        session = DropboxSession.new(DropboxExtended::APP_KEY, DropboxExtended::APP_SECRET)
      end
      session.get_request_token
      save_session session
      session
    end
    
    def save_session session
      File.open "#{PATH}dropbox-session.txt","w" do |file|
        file.puts session.serialize
      end
    end
    
    def get_authorize_url callback=""
      session = get_session
      if callback.empty?
        session.get_authorize_url
      else
        session.get_authorize_url callback
      end
    end
    
    def get_access_token
      session = get_session
      session.get_access_token
      save_session session
    end
    
    def get_client session
      DropboxClient.new(session, DropboxExtended::ACCESS_TYPE)
    end
    
    def deliver filename, folder, delivery_path
      if temp_session = get_session
        if temp_session.authorized?
          client = get_client(temp_session)
          client.file_delete "#{folder}#{delivery_path}#{filename}" rescue nil
          client.put_file "#{folder}#{delivery_path}#{filename}", open(filename) rescue nil
        end
      end
    end
    
    def reset_session
      File.delete("#{PATH}dropbox-session.txt")
    end
    
  end
  
end