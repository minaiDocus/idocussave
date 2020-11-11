require 'net/ftp'

class FileDelivery::Storage::Ftp < FileDelivery::Storage::Main
  def execute
    run do
      prepare_dir

      client.put metafile.local_path, metafile.name
    end
  end

  private

  def init_client
    code = @storage.organization.try(:code) || @storage.user.code
    ftp = Ftp::Client.new(@storage)
    ftp.connect @storage.domain, @storage.port
    ftp.login @storage.login, @storage.password
    ftp.passive = @storage.is_passive
    ftp
  end

  def max_number_of_threads
    5
  end

  def after_run
    client.close if Thread.current[:client]
  end

  def list_files
    begin
      if dir_exist?(@folder_path)
        results = client.list(@folder_path)
      else
        results = []
      end
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
        dir_exist?(@folder_path, true)
        @is_folder_ready = true
      end
    end
  end

  def dir_exist?(dir, then_create=false)
    folders = dir.split('/').reject(&:empty?)
    folders.each do |folder|
      if then_create
        client.mkdir(folder) unless client.nlst.include?(folder)
      else
        return false unless client.nlst.include?(folder)
      end
      client.chdir(folder)
    end
    true
  end

  # TODO : handle global failure and abort all attempts

  def retryable_failure?(error)
    (error.class == Net::FTPTempError && error.message.match(/Connection timed out/)) ||
    (error.class == Timeout::Error && error.message.match(/execution expired/))
  end

  def manageable_failure?(error)
    (error.class == Net::FTPPermError && error.message.match(/Login incorrect/)) ||
    (error.class == Errno::ENOTCONN && error.message.match(/Transport endpoint is not connected/))
  end

  def manage_failure(error)
    if error.class == Net::FTPPermError && error.message.match(/Login incorrect/)
      @storage.update is_configured: false
      Notifications::Ftp.new({
        ftp: @storage,
        users: @storage.organization&.admins.presence || [@storage.user],
        notice_type: @storage.organization ? 'org_ftp_auth_failure' : 'ftp_auth_failure'
      }).notify_ftp_auth_failure
    end
  end
end
