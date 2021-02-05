class Sftp::Client
  def initialize(sftp)
    @sftp = sftp

    @client = Net::SFTP.start(@sftp.domain, @sftp.login, password: @sftp.password)
  end

  def method_missing(name, *args, &block)
    # grace_time = name.in?(slow_methods) ? 120 : 5
    grace_time = 120 #TEMP FIX Set grace time to be always 120
    retries = 0
    begin
      Timeout::timeout grace_time do
        @client.send name, *args, &block
      end
    rescue Errno::ETIMEDOUT, Errno::ECONNREFUSED, Errno::ENOTCONN, Timeout::Error, EOFError => e
      log name, args

      retries += 1
      if retries < 3
        min_sleep_seconds = Float(2 ** (retries/2.0))
        max_sleep_seconds = Float(2 ** retries)
        sleep_duration = rand(min_sleep_seconds..max_sleep_seconds).round(2)
        sleep sleep_duration
        retry
      end
      @sftp.got_error e.to_s

      log_infos = {
        name: "SFTPClient",
        error_group: "[sftp-client] method missing",
        erreur_type: "SFTPClient - method missing",
        date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
        more_information: {
          method_missing_name: name,
          arguments: args.join(', '),
          retries_number: retries,
          error_message: e.message,
          backtrace_error: e.backtrace.inspect,
          sftp_id: @sftp.id,
          method: "method_missing"
        }
      }

      raise
    end
  end

  private

  def slow_methods
    [:get, :getbinaryfile, :gettextfile, :put, :putbinaryfile, :puttextfile, :login, :connect]
  end

  def log(name, args)
    _args = name == :login ? ['[FILTERED]'] : args
    System::Log.info('debug_sftp', "[SFTP ID: #{@sftp.id}] #{name} - #{_args.join(', ')}")
  end
end
