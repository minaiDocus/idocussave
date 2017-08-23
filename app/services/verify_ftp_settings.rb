class VerifyFtpSettings
  def initialize(ftp, requester=nil)
    @ftp = ftp
    @requester = requester
  end

  def execute
    ftp = nil
    begin
      Rails.logger.info "[VerifyFtpSettings][#{runner}] trying to connect to `#{@ftp.domain}:#{@ftp.port}` with user `#{@ftp.login}`..."
      ftp = Net::FTP.new
      ftp.connect @ftp.domain, @ftp.port
      ftp.login @ftp.login, @ftp.password
      ftp.passive = true
      Rails.logger.info "[VerifyFtpSettings][#{runner}] connection to `#{@ftp.domain}:#{@ftp.port}` with user `#{@ftp.login}` successful"
      true
    rescue Net::FTPPermError, SocketError, Errno::ECONNREFUSED => e
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
