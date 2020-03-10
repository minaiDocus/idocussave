class FTPClient
  def initialize(ftp)
    @client = Net::FTP.new
    @ftp = ftp
  end

  def method_missing(name, *args, &block)
    grace_time = name.in?(slow_methods) ? 120 : 5
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
      raise
    end
  end

  private

  def slow_methods
    [:get, :getbinaryfile, :gettextfile, :put, :putbinaryfile, :puttextfile, :login, :connect]
  end

  def log(name, args)
    _args = name == :login ? ['[FILTERED]'] : args
    LogService.info('debug_ftp', "[FTP ID: #{@ftp.id}] #{name} - #{_args.join(', ')}")
  end
end
