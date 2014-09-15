# -*- encoding : UTF-8 -*-
class DropboxExtended
  PATH = "#{Rails.root}/data/"

  class << self
    def file_type_to_deliver
      ExternalFileStorage::PDF
    end

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

    def reset_session
      File.delete("#{PATH}dropbox-session.txt")
    end

    def client
      @client ||= DropboxClient.new(get_session, DropboxExtended::ACCESS_TYPE)
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
        remote_path = ExternalFileStorage::delivery_path(remote_file, remote_file.receiver.dropbox_delivery_folder)
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
end
