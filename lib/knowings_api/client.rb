class KnowingsApi::Client
  attr_accessor :username, :password, :uri, :http, :request, :response


  def initialize(username, password, url)
    @uri      = URI.parse(url)
    @http     = Net::HTTP.new(@uri.host, @uri.port)
    @http.read_timeout = 15 #seconds
    @username = username
    @password = password

    if @uri.scheme == 'https'
      @http.use_ssl     = true
      @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
  end


  # Checks credentials are OK
  def verify
    @request = Net::HTTP::Get.new(@uri.path)
    @request.basic_auth @username, @password

    @response = @http.request(@request)
    @response.code.to_i == 200

  rescue Errno::ETIMEDOUT, Exception
    false
  end


  # Add a file to knowings account
  def put(filepath, remote_filepath)
    @request                = Net::HTTP::Put.new(::File.join(@uri.path, remote_filepath))
    @request.body_stream    = ::File.open(filepath)
    @request.content_type   = 'application/kzip'
    @request.content_length = ::File.size(filepath)

    @request.basic_auth @username, @password

    @response = @http.request(@request)

    @response.body.presence || @response.code.to_i
  end


  # Remove a file to knowings account
  def delete(remote_filepath)
    @request = Net::HTTP::Delete.new(::File.join(@uri.path, remote_filepath))
    @request.basic_auth @username, @password

    @response = @http.request(@request)
    @response.body.presence || @response.code.to_i
  end
end
