class Sftp::VerifySettings
  def initialize(sftp, requester=nil)
    @sftp = sftp
    @requester = requester
  end

  def execute
    sftp = nil
    begin
      System::Log.info('debug_sftp', "[VerifySftpSettings][#{runner}] trying to connect to `#{@sftp.domain}:#{@sftp.port}` with user `#{@sftp.login}`...")
      sftp = Sftp::Client.new(@sftp)

      sftp.dir.entries(@sftp.root_path || '/').map { |e| e.name }

      test_item = FileImport::Sftp::Item.new 'FOLDER_TEST', true, false

      sftp.mkdir test_item.path
      sftp.rmdir test_item.path

      System::Log.info('debug_sftp', "[VerifySftpSettings][#{runner}] connection to `#{@sftp.domain}:#{@sftp.port}` with user `#{@sftp.login}` successful")
      true
    rescue => e
      @sftp.got_error e.to_s

      System::Log.info('debug_sftp', "[VerifySftpSettings][#{runner}] connection to `#{@sftp.domain}:#{@sftp.port}` with user `#{@sftp.login}` failed with : [#{e.class}] #{e.message}")
      false
    end
  end

private

  def runner
    @requester || 'Anonym'
  end
end
