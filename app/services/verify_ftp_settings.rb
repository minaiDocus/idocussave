class VerifyFtpSettings
  def initialize(ftp, requester=nil)
    @ftp = ftp
    @requester = requester
  end

  def execute
    ftp = nil
    begin
      Rails.logger.info "[VerifyFtpSettings][#{runner}] trying to connect to `#{@ftp.domain}:#{@ftp.port}` with user `#{@ftp.login}`..."
      ftp = FTPClient.new(@ftp)
      ftp.connect @ftp.domain, @ftp.port
      ftp.login @ftp.login, @ftp.password
      ftp.passive = @ftp.is_passive

      ftp.chdir(@ftp.root_path || '/')

      ftp.nlst

      test_item = FTPImport::Item.new 'FOLDER_TEST', true, false

      ftp.mkdir test_item.path
      ftp.rmdir test_item.path

      Rails.logger.info "[VerifyFtpSettings][#{runner}] connection to `#{@ftp.domain}:#{@ftp.port}` with user `#{@ftp.login}` successful"
      true
    rescue => e
      @ftp.got_error e.to_s
      Rails.logger.info "[VerifyFtpSettings][#{runner}] connection to `#{@ftp.domain}:#{@ftp.port}` with user `#{@ftp.login}` failed with : [#{e.class}] #{e.message}"
      false
    ensure
      ftp.close if ftp
    end
  end

private

  def runner
    @requester || 'Anonym'
  end
end
