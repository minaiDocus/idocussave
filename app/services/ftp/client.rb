class Ftp::Client
  def initialize(ftp)
    @ftp = ftp

    begin
      #Verify auth ssl / tls support
      tester = Net::FTP.new( nil, ssl: { :verify_mode => OpenSSL::SSL::VERIFY_NONE } )
      tester.connect ftp.domain, ftp.port
      tester.login ftp.login, ftp.password
      tester.close

      @client = Net::FTP.new( nil, ssl: { :verify_mode => OpenSSL::SSL::VERIFY_NONE } )
    rescue => e
      log_infos = {
        subject: "[Ftp::Client] verify auth ssl / tls support #{e.message}",
        name: "FTPClient",
        error_group: "[ftp-client] verify auth ssl / tls support",
        erreur_type: "FTPClient - Verify auth ssl / tls support",
        date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
        more_information: {
          error_type: e.class,
          error_message: e.message,
          backtrace_error: e.backtrace.inspect,
          ftp_id: @ftp.id
        }
      }

      ErrorScriptMailer.error_notification(log_infos).deliver

      @client = Net::FTP.new(nil)
    end
  end

  def method_missing(name, *args, &block)
    # grace_time = name.in?(slow_methods) ? 120 : 5
    grace_time = 120 #TEMP FIX Set grace time to be always 120
    retries = 0
    begin
      Timeout::timeout grace_time do
        @client.send name, *args, &block
      end
    rescue Errno::ETIMEDOUT, Errno::ECONNREFUSED, Errno::ENOTCONN, Timeout::Error, Net::FTPTempError, EOFError => e
      log name, args

      retries += 1
      if retries < 3
        min_sleep_seconds = Float(2 ** (retries/2.0))
        max_sleep_seconds = Float(2 ** retries)
        sleep_duration = rand(min_sleep_seconds..max_sleep_seconds).round(2)
        sleep sleep_duration
        retry
      end
      @ftp.got_error e.to_s

      log_infos = {
        subject: "[Ftp::Client]  method missing #{e.message}",
        name: "FTPClient",
        error_group: "[ftp-client] method missing",
        erreur_type: "FTPClient - method missing",
        date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
        more_information: {
          method_missing_name: name,
          arguments: args.join(', '),
          retries_number: retries,
          error_message: e.message,
          backtrace_error: e.backtrace.inspect,
          ftp_id: @ftp.id,
          method: "method_missing"
        }
      }

      ErrorScriptMailer.error_notification(log_infos).deliver

      raise
    end
  end

  private

  def slow_methods
    [:get, :getbinaryfile, :gettextfile, :put, :putbinaryfile, :puttextfile, :login, :connect]
  end

  def log(name, args)
    _args = name == :login ? ['[FILTERED]'] : args
    System::Log.info('debug_ftp', "[FTP ID: #{@ftp.id}] #{name} - #{_args.join(', ')}")
  end
end
