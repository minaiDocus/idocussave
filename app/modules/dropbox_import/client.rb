class DropboxImport::Client
  def initialize(client)
    @client = client
  end

  def method_missing(name, *args)
    tried_count = 1
    begin
      @client.send(name, *args)
    rescue Errno::ETIMEDOUT, Timeout::Error, DropboxError => e
      if e.class.in?([Errno::ETIMEDOUT, Timeout::Error]) || e.message.match(/503 Service Unavailable|Internal Server Error|Please re-issue the request/)
        if tried_count <= 3
          sleep(5 * tried_count)
          tried_count += 1
          retry
        end
      end
      raise
    end
  end
end
