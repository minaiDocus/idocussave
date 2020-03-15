module ApiBroker
  class Request
    def initialize(base_url, content_type, authentication_header = nil, authentication_key = nil, basic_auth = nil)
      @base_url = base_url
      @basic_auth = basic_auth
      @content_type = content_type
      @authentication_key    = authentication_key
      @authentication_header = authentication_header

      @connection = Faraday.new(@base_url) do |faraday|
        faraday.response :logger
        faraday.adapter Faraday.default_adapter
        faraday.headers['Content-Type'] = @content_type
        faraday.headers[@authentication_header.to_s] = @authentication_key
      end
    end

    def perform(path, verb, params = nil, payload = nil)
      case verb
      when :get
        result = @connection.get do |request|
          request.url "#{path}#{params}"
        end
      when :post
        result = @connection.post do |request|
          request.url "#{path}#{params}"
          request.body = payload
        end
      when :put
        result = @connection.put do |request|
          request.url "#{path}#{params}"
          request.body = payload
        end
      when :patch
        result = @connection.patch do |request|
          request.url "#{path}#{params}"
          request.body = payload
        end
      when :delete
        result = @connection.delete do |request|
          request.url "#{path}#{params}"
        end
      else
        raise 'Invalid verb'
      end

      result
    end
  end
end