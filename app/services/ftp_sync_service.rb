require 'net/ftp'

class FtpSyncService
  def initialize(remote_files)
    @remote_files = remote_files

    @ftp = remote_files.first.receiver.external_file_storage.ftp
  end


  def execute
    remote_path = ExternalFileStorage.delivery_path(@remote_files.first, @ftp.path)
    is_ok = true

    begin
      change_or_make_dir(remote_path)
    rescue => e
      is_ok = false
      @remote_files.each do |remote_file|
        remote_file.not_synced!("[#{e.class}] #{e.message}")
      end
    end

    if is_ok
      @remote_files.each_with_index do |remote_file, index|
        remote_filepath = File.join(remote_path, remote_file.name)
        tries = 0

        begin
          remote_file.sending!(remote_filepath)

          print "\t[#{'%0.3d' % (index + 1)}] \"#{remote_filepath}\" "

          if is_not_updated(remote_file.name, remote_file.local_path)
            print 'sending...'

            client.put(remote_file.local_path, remote_file.name)

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
            puts "\t[#{'%0.3d' % (index + 1)}] Retrying later"

            remote_file.not_synced!("[#{e.class}] #{e.message}")
          end
        end
      end
    end

    client.chdir('/')

    close_connection
  end


  def change_or_make_dir(pathname)
    folders = pathname.split('/').reject(&:empty?)

    folders.each do |folder|
      begin
        client.mkdir(folder)
      rescue
        nil
      end

      client.chdir(folder)
    end
  end

  def client
    if @ftp.is_configured?
      @client ||= Net::FTP.new(@ftp.host.sub(/\Aftp:\/\//, ''), @ftp.login, @ftp.password)
    end
  end


  def close_connection
    if @client
      @client.close

      @client = nil
    end
  end


  def is_updated(remote_file_name, file_path)
    result = client.list.select { |entry| entry.force_encoding('UTF-8').match(/#{remote_file_name}/) }.first
    if result
      size = begin
               result.split(/\s/).reject(&:empty?)[4].to_i
             rescue
               0
             end
      if size == File.size(file_path)
        true
      else
        false
      end
    else
      false
    end
  end


  def is_not_updated(remote_file_name, file_path)
    !is_updated(remote_file_name, file_path)
  end
end
