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
    
    def save_session(session)
      File.open "#{PATH}dropbox-session.txt","w" do |file|
        file.puts session.serialize
      end
    end
    
    def get_authorize_url(callback='')
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
      path.gsub(":code",info_path[:code]).
      gsub(":company",info_path[:company]).
      gsub(":account_book",info_path[:account_book]).
      gsub(":year",info_path[:year]).
      gsub(":month",info_path[:month]).
      gsub(":delivery_date",info_path[:delivery_date])
    end

    def is_updated(path, filename, client)
      begin
        results = client.search(path,filename,1)
      rescue DropboxError => e
        Delivery::ErrorStack.create(sender: 'DropboxExtended', description: 'search', filename: filename, message: e)
      end
      if results.any?
        size = result["bytes"]
        if size == File.size(filename)
          true
        else
          false
        end
      else
        nil
      end
    end
    
    def is_not_updated(path, filename, client)
      !is_updated(path, filename, client)
    end
    
    def deliver(filespath, folder, infopath)
      if temp_session = get_session
        if temp_session.authorized?
          delivery_path = static_path(folder, infopath)
          clean_path = delivery_path.sub(/\/$/,"")
          client = get_client(temp_session)
          filespath.each do |filepath|
            filename = File.basename(filepath)
            if (result = is_not_updated(clean_path, filename, client))
              if result == false
                begin
                  client.file_delete "#{clean_path}/#{filename}"
                rescue DropboxError => e
                  Delivery::ErrorStack.create(sender: 'DropboxExtended', description: 'deleting', filename: filename, message: e)
                end
              end
              begin
                client.put_file "#{clean_path}/#{filename}", file
              rescue DropboxError => e
                Delivery::ErrorStack.create(sender: 'DropboxExtended', description: 'sending', filename: filename, message: e)
              end
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
