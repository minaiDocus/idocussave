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
    
    def client
      @client ||= DropboxClient.new(get_session, DropboxExtended::ACCESS_TYPE)
    end

    def static_path(path, info_path)
      path.gsub(":code",info_path[:code]).
      gsub(":company",info_path[:company]).
      gsub(":account_book",info_path[:account_book]).
      gsub(":year",info_path[:year]).
      gsub(":month",info_path[:month]).
      gsub(":delivery_date",info_path[:delivery_date])
    end

    def is_up_to_date(path, filepath)
      filename = File.basename(filepath)
      begin
        results = client.search(path,filename,1)
      rescue DropboxError => e
        Delivery::Error.create(sender: 'DropboxExtended', state: 'searching', filepath: "#{path}/#{filename}", message: e)
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
    
    def deliver(filespath, folder, infopath)
      if client
        delivery_path = static_path(folder, infopath)
        clean_path = delivery_path.sub(/\/$/,"")
        filespath.each do |filepath|
          filename = File.basename(filepath)
          if is_not_up_to_date(clean_path,filepath)
            begin
              client.put_file("#{clean_path}/#{filename}", open(filepath), true)
            rescue DropboxError => e
              Delivery::Error.create(sender: 'DropboxExtended', state: 'sending', filepath: "#{clean_path}/#{filename}", message: e)
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
