class FTPClient
  def initialize(message_prefix)
    @client = Net::FTP.new
    @message_prefix = message_prefix
  end

  def method_missing(name, *args, &block)
    grace_time = name.in?(slow_methods) ? 120 : 5
    retries = 0
    begin
      log name, args

      Timeout::timeout grace_time do
        @client.send name, *args, &block
      end
    rescue Errno::ETIMEDOUT, Errno::ECONNREFUSED, Timeout::Error, Net::FTPTempError, EOFError
      retries += 1
      if retries < 3
        min_sleep_seconds = Float(2 ** (retries/2.0))
        max_sleep_seconds = Float(2 ** retries)
        sleep_duration = rand(min_sleep_seconds..max_sleep_seconds).round(2)
        sleep sleep_duration
        retry
      end
      raise
    end
  end

  private

  def slow_methods
    [:get, :getbinaryfile, :gettextfile, :put, :putbinaryfile, :puttextfile]
  end

  def logger
    @logger ||= Logger.new("#{Rails.root}/log/#{Rails.env}_debug_ftp.log")
  end

  def log(name, args)
    _args = name == :login ? ['[FILTERED]'] : args
    logger.info "[#{@message_prefix}] #{name} - #{_args.join(', ')}"
  end
end
