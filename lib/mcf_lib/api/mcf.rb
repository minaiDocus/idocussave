# -*- encoding : UTF-8 -*-
module McfLib
  module Api
    class Mcf
      class Client
        attr_accessor :access_token
        attr_reader :request, :response

        def initialize(access_token)
          @access_token = access_token
        end

        def move_uploaded_file
          @response = send_request('https://uploadservice.mycompanyfiles.fr/api/idocus/moveobject', { 'AccessToken' => @access_token })
          data_response = handle_response
        end

        def ask_to_resend_file
          @response = send_request('https://uploadservice.mycompanyfiles.fr/api/idocus/resendobject', { 'AccessToken' => @access_token })
          data_response = handle_response
        end

        def renew_access_token(refresh_token)
          @response = send_request('https://uploadservice.mycompanyfiles.fr/api/idocus/TakeAnotherToken', { 'RefreshToken' => refresh_token })
          data_response = handle_response

          @access_token = data_response['AccessToken']
          { access_token: data_response['AccessToken'], expires_at: DateTime.strptime(data_response['ExpirationDate'].to_s,'%Q') }
        end

        def accounts
          @response = send_request('https://uploadservice.mycompanyfiles.fr/api/idocus/TakeAllStorages', { 'AccessToken' => @access_token, 'AttributeName' => 'Storage' })
          data_response = handle_response

          data_response['ListStorageDto'].select{ |storage| storage["Read"] && storage["Write"] && !storage["IsArchive"] }.collect{ |storage| storage["Name"] }
        end

        def upload(file_path, remote_path, force=true)
          remote_storage = remote_path.split("/")[0]
          remote_path.slice!("#{remote_storage}/")

          #IMPORTANT-WORKAROUND : Mcf upload doesn't support faraday request
          @response = send_typhoeus_request('https://uploadservice.mycompanyfiles.fr/api/idocus/Upload', {  accessToken: @access_token,
                                                                                                            attributeName:  "Storage",
                                                                                                            attributeValue: remote_storage,
                                                                                                            sendMail:    'false',
                                                                                                            force:       force.to_s,
                                                                                                            pathFile:    remote_path,
                                                                                                            file:        File.open(file_path, 'r')
                                                                                                          })
          data_response = handle_response
        end

        def verify_files(file_paths)
          remote_storage = file_paths.first.split("/")[0]
          file_paths = file_paths.map { |path| path.sub("#{remote_storage}/", "") }

          @response = send_request('https://uploadservice.mycompanyfiles.fr/api/idocus/VerifyFile', {
                                                                                                      AccessToken:    @access_token,
                                                                                                      AttributeName:  "Storage",
                                                                                                      AttributeValue: remote_storage,
                                                                                                      ListPath:       file_paths
                                                                                                    })

          if @response.status.to_i == 200
            if @response.body.match(/(access token doesn't exist|argument missing AccessToken)/i)
              raise Errors::Unauthorized
            else
              data = JSON.parse(@response.body)
              data.select do |info|
                info['Status'] == 600
              end.map do |info|
                { path: File.join(remote_storage, info['Path']), md5: info['Md5'] }
              end
            end
          elsif @response.status.to_i == 0
            []
          else
            raise Errors::Unknown.new("#{@response.status} / verif=> #{@response.body}")
          end
        end

        private

        def connection(url)
          Faraday.new(:url => url) do |f|
            f.response :logger
            f.adapter Faraday.default_adapter
          end
        end

        def handle_response
          status = @response.try(:code).presence || @response.try(:status).presence

          if status.to_i == 200
            data = JSON.parse(@response.body)
            if data['Status'] == 600 || data['CodeError'] == 600
              data
            elsif data['Message'].match(/(access token doesn't exist|argument missing AccessToken)/i)
              raise Errors::Unauthorized
            else
              raise Errors::Unknown.new("#{status} / response=> #{data.to_s}")
            end
          else
            error_mess = status
            error_mess = @response.body if @response.body.present?

            raise Errors::Unknown.new("#{status} / response=> #{error_mess}")
          end
        end

        def send_request(uri, params)
          @response = connection(uri).post do |request|
            request.headers = { accept: 'json' }
            request.options.timeout = 180
            request.body = params.to_query #params.to_json not supported
          end
        end

        def send_typhoeus_request(uri, params)
          @request = Typhoeus::Request.new(
            uri,
            method:  :post,
            headers: { accept: :json },
            timeout: 180,
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
  end
end
