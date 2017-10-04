require 'net/ftp'

class SendToFTP < SendToStorage
  def execute
    run do
      prepare_dir

      client.put metafile.local_path, metafile.name
    end
  end

  private

  def init_client
    ftp = Net::FTP.new
    ftp.connect @storage.domain, @storage.port
    ftp.login @storage.login, @storage.password
    ftp.passive = @storage.is_passive
    ftp
  end

  def max_number_of_threads
    5
  end

  def after_run
    client.close
  end

  def list_files
    begin
      results = client.list(@folder_path)
    rescue Net::FTPTempError, Net::FTPPermError => e
      if e.message.match(/(No such file or directory)|(Directory not found)/)
        results = []
      else
        raise
      end
    end
    results.map do |e|
      data = e.split(/\s/).reject(&:empty?)
      [data[-1], data[4].to_i]
    end
  end

  def prepare_dir
    @semaphore.synchronize do
      if @is_folder_ready
        # TODO : avoid changing directory for each run
        client.chdir @folder_path
      else
        client.chdir '/'
        folders = @folder_path.split('/').reject(&:empty?)
        folders.each do |folder|
          client.mkdir(folder) unless client.nlst.include?(folder)
          client.chdir(folder)
        end
        @is_folder_ready = true
      end
    end
  end

  def retryable_failure?(error)
    false
  end

  def manageable_failure?(error)
    error.class == Net::FTPPermError && error.message.match(/530 Login incorrect/)
  end

  def manage_failure(error)
    false
  end
end
