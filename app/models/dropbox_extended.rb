# -*- encoding : UTF-8 -*-
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
    
    def static_path(path, info_path)
      delivery_path = path
      delivery_path = delivery_path.gsub(":code",info_path[:code])
      delivery_path = delivery_path.gsub(":company",info_path[:company])
      delivery_path = delivery_path.gsub(":account_book",info_path[:account_book])
      delivery_path = delivery_path.gsub(":year",info_path[:year])
      delivery_path = delivery_path.gsub(":month",info_path[:month])
      delivery_path = delivery_path.gsub(":delivery_date",info_path[:delivery_date])
      delivery_path
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
    
    def deliver filespath, folder, infopath
      if temp_session = get_session
        if temp_session.authorized?
          delivery_path = static_path(folder, infopath)
          clean_path = delivery_path.sub(/\/$/,"")
          client = get_client(temp_session)
          filespath.each do |filepath|
            filename = File.basename(filepath)
            if is_not_updated(clean_path, filename, client)
              client.file_delete "#{clean_path}/#{filename}" rescue nil
              client.put_file "#{clean_path}/#{filename}", open(filename) rescue nil
            end
          end
        end
      end
    end
    
    def reset_session
      File.delete("#{PATH}dropbox-session.txt")
    end
    
  end
  
end
