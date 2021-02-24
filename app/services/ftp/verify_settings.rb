class Ftp::VerifySettings
  def initialize(ftp, requester=nil)
    @ftp = ftp
    @requester = requester
  end

  def execute
    ftp = nil
    begin
      System::Log.info('debug_ftp', "[VerifyFtpSettings][#{runner}] trying to connect to `#{@ftp.domain}:#{@ftp.port}` with user `#{@ftp.login}`...")
      ftp = Ftp::Client.new(@ftp)
      ftp.connect @ftp.domain, @ftp.port
      ftp.login @ftp.login, @ftp.password
      ftp.passive = @ftp.is_passive

      ftp.chdir(@ftp.root_path || '/')

      ftp.nlst

      test_item = FileImport::Ftp::Item.new 'FOLDER_TEST', true, false

      ftp.mkdir test_item.path
      ftp.rmdir test_item.path

      System::Log.info('debug_ftp', "[VerifyFtpSettings][#{runner}] connection to `#{@ftp.domain}:#{@ftp.port}` with user `#{@ftp.login}` successful")
      true
    rescue => e
      @ftp.got_error e.to_s

      log_infos = {
        subject: "[Ftp::VerifySettings]  execute #{e.message}",
        name: "VerifyFtpSettings",
        error_group: "[verify-ftp-settings] execute",
        erreur_type: "VerifyFtpSettings - execute",
        date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
        more_information: {
          runner: runner,
          ftp_domain: @ftp.domain,
          ftp_port: @ftp.port,
          user: @ftp.login,
          error_type: e.class,
          error_message: e.message,
          backtrace_error: e.backtrace.inspect,
          method: "execute"
        }
      }

      ErrorScriptMailer.error_notification(log_infos).deliver

      System::Log.info('debug_ftp', "[VerifyFtpSettings][#{runner}] connection to `#{@ftp.domain}:#{@ftp.port}` with user `#{@ftp.login}` failed with : [#{e.class}] #{e.message}")
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
