class McfApi
  class Client
    attr_accessor :access_token
    attr_reader :request, :response

    def initialize(access_token)
      @access_token = access_token
    end

    def move_uploaded_file
      @response = send_request('https://uploadservice-preprod.mycompanyfiles.fr/api/idocus/moveobject', { 'AccessToken' => @access_token })
      data_response = handle_response
    end

    def ask_to_resend_file
      @response = send_request('https://uploadservice-preprod.mycompanyfiles.fr/api/idocus/resendobject', { 'AccessToken' => @access_token })
      data_response = handle_response
    end

    def renew_access_token(refresh_token)
      @response = send_request('https://uploadservice.mycompanyfiles.fr/api/idocus/TakeAnotherToken', { 'refreshToken' => refresh_token })
      data_response = handle_response

      @access_token = data_response['AccessToken']
      { access_token: data_response['AccessToken'], expires_at: DateTime.strptime(data_response['ExpirationDate'].to_s,'%Q') }
    end

    def accounts
      @response = send_request('https://uploadservice.mycompanyfiles.fr/api/idocus/TakeStorageFullRight', { 'AccessToken' => @access_token })
      data_response = handle_response

      data_response['ListStorage']
    end

    def upload(file_path, remote_path, force=true)
      @response = send_request('https://uploadservice.mycompanyfiles.fr/api/idocus/UploadToMCF', {  accessToken: @access_token,
                                                                                                    sendMail:    'false',
                                                                                                    force:       force.to_s,
                                                                                                    pathFile:    remote_path,
                                                                                                    file:        File.open(file_path, 'r') 
                                                                                                  })
      data_response = handle_response
    end

    def verify_files(file_paths)
     @request = Typhoeus::Request.new(
        'https://uploadservice.mycompanyfiles.fr/api/idocus/VerifyFileInMcf',
        method:  :post,
        headers: { accept: :json },
        timeout: 10,
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

    private

    def handle_response
      if @response.code == 200
        data = JSON.parse(@response.body)
        if data['Status'] == 600 || data['CodeError'] == 600
          data
        elsif data['Message'].match(/(access token doesn't exist|argument missing AccessToken)/i)
          raise Errors::Unauthorized
        else
          raise Errors::Unknown.new(data.to_s)
        end
      else
        error_mess = @response.code if @response.code.present?
        error_mess = @response.return_code if @response.return_code.present?
        error_mess = @response.body if @response.body.present?

        raise Errors::Unknown.new(error_mess)
      end
    end

    def send_request(uri, params)
      @request = Typhoeus::Request.new(
        uri,
        method:  :post,
        headers: { accept: :json },
        timeout: 10,
        body: params   
      )
      @request.run
    end

  end

  class Errors
    class Unauthorized < RuntimeError; end
    class Unknown < RuntimeError; end
  end
end
