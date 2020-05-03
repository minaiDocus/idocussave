class IbizaAPI::Client
  attr_accessor :token, :partner_id, :request, :response

  def initialize(token, callback=nil)
    @token      = token
    @request    = Request.new(self, callback)
    @response   = Response.new
    @partner_id = IbizaAPI::Config::PARTNER_ID
  end


  def method_missing(name, *args)
    append(name, *args)
  end


  def append(name, *args)
    name = name.to_s

    if name.to_s =~ /\A(.*)(!|\?)\z/
      @request << Regexp.last_match(1)

      if args.any?
        if Regexp.last_match(2) == '!'
          @request.body = args.first
        else
          args.each do |arg|
            @request << arg
          end
        end
      end

      @request.method = Regexp.last_match(2) == '!' ? :post : :get

      return @request.run
    else
      @request << name

      if args.any?
        args.each do |arg|
          @request << arg
        end
      end

      self
    end
  end


  class Request
    attr_accessor :client, :path, :method, :body, :original


    def initialize(client, callback=nil)
      @path = ''
      @body = ''
      @method = :get
      @client = client
      @callback = callback
    end


    def <<(path)
      @path << "/#{path}"
    end


    def path?
      !@path.empty?
    end


    def url
      URI.encode("#{base}#{@path}")
    end


    def base
      IbizaAPI::Config::ROOT_URL
    end


    def clear
      @path = ''
      @method = :get
    end


    def run
      @original = Typhoeus::Request.new(
        url,
        method:  @method,
        body:    @body,
        headers: {
          'content-type' => 'application/xml',
          irfToken: @client.token,
          partnerID: @client.partner_id
        }
      )

      @client.response.original = @original.run

      @callback.after_run(@client.response) if @callback

      @client.response.result || @client.response.code
    end
  end


  class Response
    attr_accessor :original, :result, :datetime, :message, :data_type, :data


    def method_missing(name, *args)
      @original.send(name, *args)
    rescue NoMethodError
      @original.parse_body(name)
    end


    def original=(original)
      @original = original
      if original.headers['Content-Type'].present? && original.headers['Content-Type'].split(';')[0] == 'application/xml'
        hash = Hash.from_xml(original.body).first

        response = hash.last['response']

        @result = response['result']

        @datetime = response['datetime'].to_time

        if response['message'].present? && response['message'] != { 'i:nil' => 'true' }
          if @result == 'Error' && response['message']['error'].try(:[], 'number') && response['message']['error'].try(:[], 'description')
            @message = "Erreur n°#{response['message']['error']['number']} - #{response['message']['error']['description']}"
          else
            @message = response['message']
          end
        end

        if hash.last['data']
          @data_type = hash.last['data'].keys.last

          @data = hash.last['data'][@data_type]

          if @data.is_a? Hash
            @data = [@data]
          elsif !@data.is_a? Array
            @data = []
          end
        end
      else
        @result = @datetime = @message = @data_type = @data = nil
      end
    end


    def success?
      @result.try(:downcase) == 'success'
    end
  end
end
