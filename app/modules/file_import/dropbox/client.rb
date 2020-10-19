class FileImport::Dropbox::Client
  def initialize(client)
    @client = client
  end

  def method_missing(name, *args, &block)
    retries = 0
    begin
      @client.send(name, *args, &block)
    rescue Errno::ETIMEDOUT, Timeout::Error, Faraday::ConnectionFailed, DropboxApi::Errors::InternalError, DropboxApi::Errors::RateLimitError, DropboxApi::Errors::TooManyWriteOperationsError, DropboxApi::Errors::HttpError
      retries += 1
      if retries < 5
        min_sleep_seconds = Float(2 ** (retries/2.0))
        max_sleep_seconds = Float(2 ** retries)
        sleep_duration = rand(min_sleep_seconds..max_sleep_seconds).round(2)
        sleep sleep_duration
        retry
      end
      raise
    end
  end
end
