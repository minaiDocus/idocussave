class VerifyFtpSettings
  def initialize(ftp, requester=nil)
    @ftp = ftp
    @requester = requester
  end

  def execute
    session = nil
    begin
      Rails.logger.info "[VerifyFtpSettings][#{runner}] trying to connect to `#{@ftp.domain}` with user `#{@ftp.login}`..."
      session = Net::FTP.new @ftp.domain, @ftp.login, @ftp.password
      Rails.logger.info "[VerifyFtpSettings][#{runner}] connection to `#{@ftp.domain}` with user `#{@ftp.login}` successful"
      true
    rescue Net::FTPPermError, SocketError, Errno::ECONNREFUSED => e
      Rails.logger.info "[VerifyFtpSettings][#{runner}] connection to `#{@ftp.domain}` with user `#{@ftp.login}` failed with : [#{e.class}] #{e.message}"
      false
    ensure
      session.close if session
    end
  end

private

  def runner
    @requester || 'Anonym'
  end
end
