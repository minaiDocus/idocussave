class McfApi
  class Client
    attr_accessor :access_token
    attr_reader :request, :response

    def initialize(access_token)
      @access_token = access_token
    end

    def renew_access_token(refresh_token)
      @request = Typhoeus::Request.new(
        'https://uploadservice.mycompanyfiles.fr/api/idocus/TakeAnotherToken',
        method:  :post,
        headers: { accept: :json },
        body:    { 'refreshToken' => refresh_token }
      )
      @response = @request.run
      if @response.code == 200
        data = JSON.parse(@response.body)
        if data['Message'] == 'Success'
          @access_token = data['AccessToken']
          { access_token: data['AccessToken'], expires_at: DateTime.strptime(data['ExpirationDate'].to_s,'%Q') }
        else
          raise Errors::Unknown.new(data)
        end
      else
        raise Errors::Unknown.new(@response.body)
      end
    end

    def accounts
      @request = Typhoeus::Request.new(
        'https://uploadservice.mycompanyfiles.fr/api/idocus/TakeStorageFullRight',
        method:  :post,
        headers: { accept: :json },
        body:    { 'accessToken' => @access_token }
      )
      @response = @request.run
      if @response.code == 200
        data = JSON.parse(@response.body)
        if data['Message'] == 'Success'
          data['ListStorage']
        elsif data['Message'].match(/(access token doesn't exist|argument missing AccessToken)/i)
          raise Errors::Unauthorized
        else
          raise Errors::Unknown.new(data)
        end
      else
        raise Errors::Unknown.new(@response.body)
      end
    end

    def upload(file_path, remote_path, force=true)
      @request = Typhoeus::Request.new(
        'https://uploadservice.mycompanyfiles.fr/api/idocus/UploadToMCF',
        method:  :post,
        headers: { accept: :json },
        body: {
          accessToken: @access_token,
          sendMail:    'false',
          force:       force.to_s,
          pathFile:    remote_path,
          file:        File.open(file_path, 'r')
        }
      )
      @response = @request.run
      if @response.code == 200
        result = JSON.parse @response.body
        if result['Success'] == true
          result
        elsif data['Message'].match(/(access token doesn't exist|argument missing AccessToken)/i)
          raise Errors::Unauthorized
        else
          raise Errors::Unknown.new(@response.body)
        end
      else
        raise Errors::Unknown.new(@response.body)
      end
    end

    def verify_files(file_paths)
      @request = Typhoeus::Request.new(
        'https://uploadservice.mycompanyfiles.fr/api/idocus/VerifyFileInMcf',
        method:  :post,
        headers: { accept: :json },
        body:    {
          accessToken:   @access_token,
          withAttribute: false,
          isAdmin:       false,
          listPath:      file_paths
        }
      )
      @response = @request.run
      if @response.code == 200
        if @response.body.match(/(access token doesn't exist|argument missing AccessToken)/i)
          raise Errors::Unauthorized
        else
          data = JSON.parse(@response.body)
          data.select do |info|
            info['Status'] == 600
          end.map do |info|
            { path: info['Path'], md5: info['Md5'] }
          end
        end
      else
        raise Errors::Unknown.new(@response.body)
      end
    end
  end

  class Errors
    class Unauthorized < RuntimeError; end
    class Unknown < RuntimeError; end
  end
end
