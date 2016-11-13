class Budgea
  class << self
    def configure
      yield config
    end

    def config
      @config ||= Configuration.new
    end

    def config=(new_config)
      config.domain        = new_config['domain']        if new_config['domain']
      config.client_id     = new_config['client_id']     if new_config['client_id']
      config.client_secret = new_config['client_secret'] if new_config['client_secret']
      config.redirect_uri  = new_config['redirect_uri']  if new_config['redirect_uri']
    end
  end

  class Configuration
    attr_accessor :domain, :client_id, :client_secret, :redirect_uri
  end

  class Client
    attr_accessor :request
    attr_accessor :response
    attr_accessor :access_token
    attr_accessor :user_id
    attr_accessor :error_message

    def initialize(access_token=nil, user_id=nil)
      # NOTE is settings variable really needed ?
      @settings = {
        :base_url      => "https://#{Budgea.config.domain}/2.0",
        :client_id     => Budgea.config.client_id,
        :client_secret => Budgea.config.client_secret,
      }
      # NOTE access_token is used only for limiting the scope of a request to the user only, because we could use the couple client_id/client_secret or manage_token to do all the request since it's all server side
      @access_token = access_token
      @user_id = user_id
    end

    def create_user
      @request = Typhoeus::Request.new(
        @settings[:base_url] + '/auth/init',
        method:  :post,
        headers: { accept: :json },
        params:  authentification_params
      )
      @response = @request.run
      if @response.code == 200
        result = JSON.parse(@response.body)
        if result['type'] == 'permanent'
          @access_token = result['auth_token']
        else
          false
        end
      else
        false
      end
    end

    def destroy_user
      if @access_token.present?
        @request = Typhoeus::Request.new(
          @settings[:base_url] + '/users/me',
          method:  :delete,
          headers: headers
        )
        @response = @request.run
        if @response.code == 200
          @access_token = nil
          true
        else
          false
        end
      else
        false
      end
    end

    # for use on client side
    # def get_temporary_token
    #   @request = Typhoeus::Request.new(
    #     @settings[:base_url] + '/auth/token/code',
    #     method:  :get,
    #     headers: headers
    #   )
    #   @response = @request.run
    #   JSON.parse(@response.body)['code']
    # end

    def get_banks
      @request = Typhoeus::Request.new(
        @settings[:base_url] + '/banks?expand=fields',
        method:  :get,
        headers: { accept: :json },
        params:  authentification_params
      )
      @response = @request.run
      result = JSON.parse(@response.body)
      result['banks'] ? result['banks'] : result
    end

    def get_providers
      @request = Typhoeus::Request.new(
        @settings[:base_url] + '/providers?expand=fields',
        method:  :get,
        headers: { accept: :json },
        params:  authentification_params
      )
      @response = @request.run
      result = JSON.parse(@response.body)
      # NOTE it is really 'banks' here...
      result['banks'] ? result['banks'] : result
    end

    def get_categories
      @request = Typhoeus::Request.new(
        @settings[:base_url] + '/categories',
        method:  :get,
        headers: { accept: :json },
        params:  authentification_params
      )
      @response = @request.run
      result = JSON.parse(@response.body)
      result['categories'] ? result['categories'] : result
    end

    def get_profiles
      @request = Typhoeus::Request.new(
        @settings[:base_url] + '/users/me/profiles',
        method:  :get,
        headers: headers
      )
      @response = @request.run
      if @response.code == 200
        result = JSON.parse(@response.body)
        @user_id = result['profiles'].first['id_user'] unless @user_id
        result['profiles']
      else
        @response.body
      end
    end

    def get_new_access_token(user_id)
      @request = Typhoeus::Request.new(
        @settings[:base_url] + "/users/#{user_id}/token",
        method:  :post,
        headers: headers,
        params:  { application: 'sharedAccess' }
      )
      @response = @request.run
      parsed_response
    end

    def delete_access_token
      @request = Typhoeus::Request.new(
        @settings[:base_url] + '/users/me/token',
        method:  :delete,
        headers: headers
      )
      @response = @request.run
      @response.code == 200
    end

    def request_new_connector(params)
      @request = Typhoeus::Request.new(
        @settings[:base_url] + '/connectors',
        method:  :post,
        headers: { accept: :json },
        params:  authentification_params.merge(params)
      )
      @response = @request.run
      parsed_response
    end

    def create_connection(params)
      @request = Typhoeus::Request.new(
        @settings[:base_url] + '/users/me/connections',
        method:  :post,
        headers: headers,
        params:  params
      )
      @response = @request.run
      parsed_response
    end

    def update_connection(id, params)
      @request = Typhoeus::Request.new(
        @settings[:base_url] + "/users/me/connections/#{id}",
        method:  :post,
        headers: headers,
        body:    params
      )
      @response = @request.run
      parsed_response
    end

    def destroy_connection(id)
      @request = Typhoeus::Request.new(
        @settings[:base_url] + "/users/me/connections/#{id}",
        method:  :delete,
        headers: headers
      )
      @response = @request.run
      @response.code == 200
    end

    def sync_connection(id)
      @request = Typhoeus::Request.new(
        @settings[:base_url] + "/users/me/connections/#{id}",
        method:  :put,
        headers: headers
      )
      @response = @request.run
      parsed_response
    end

    def get_accounts
      @request = Typhoeus::Request.new(
        @settings[:base_url] + '/users/me/accounts',
        method:  :get,
        headers: headers
      )
      @response = @request.run
      result = JSON.parse(@response.body)
      result['accounts'] ? result['accounts'] : result
    end

    def get_transactions(account_id)
      @request = Typhoeus::Request.new(
        @settings[:base_url] + "/users/me/accounts/#{account_id}/transactions",
        method:  :get,
        headers: headers
      )
      @response = @request.run
      result = JSON.parse(@response.body)
      result['transactions'] ? result['transactions'] : result
    end

    def get_documents(connection_id=nil)
      path = '/users/me'
      path += "/connections/#{connection_id}" if connection_id
      path += '/documents'
      @request = Typhoeus::Request.new(
        @settings[:base_url] + path,
        method:  :get,
        headers: headers
      )
      @response = @request.run
      result = JSON.parse(@response.body)
      result['documents'] ? result['documents'] : result
    end

    def get_file(document_id)
      @request = Typhoeus::Request.new(
        @settings[:base_url] + "/users/me/documents/#{document_id}/file",
        method:  :get,
        headers: headers
      )
      @response = @request.run
      if @response.code == 200
        file = Tempfile.new(['', '.pdf'])
        file.write @response.body.force_encoding('UTF-8')
        file.close
        file.path
      else
        begin
          JSON.parse(@response.body)
        rescue JSON::ParserError
          @response.body
        end
      end
    end

  private

    def headers
      {
        accept: :json,
        'Authorization' => "Bearer #{@access_token}"
      }
    end

    def authentification_params
      {
        client_id:     @settings[:client_id],
        client_secret: @settings[:client_secret]
      }
    end

    def parsed_response
      if @response.code.in? [200, 202, 204, 400, 403, 500, 503]
        result = JSON.parse(@response.body)
        @error_message = case result['code']
                         when 'wrongpass'
                           'Mot de passe incorrecte.'
                         when 'websiteUnavailable'
                           'Site web indisponible.'
                         when 'bug'
                           'Service indisponible.'
                         else
                           nil
                         end
        if result['message'] && result['message'].match(/Can't force synchronization of connection/)
          @error_message = 'Ne peut pas forcer la synchronisation.'
        end
        result
      else
        @error_message = @response.body
      end
    end
  end

  class Errors
    class ServiceUnavailable < RuntimeError; end
  end
end
