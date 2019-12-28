class Budgea
  class << self
    def configure
      yield config
    end

    def config
      @config ||= Configuration.new
    end

    def config=(new_config)
      config.domain         = new_config['domain']          if new_config['domain']
      config.client_id      = new_config['client_id']       if new_config['client_id']
      config.client_secret  = new_config['client_secret']   if new_config['client_secret']
      config.redirect_uri   = new_config['redirect_uri']    if new_config['redirect_uri']
      config.encryption_key = new_config['encryption_key']  if new_config['encryption_key']
      config.proxy          = new_config['proxy']           if new_config['proxy']
    end
  end

  class Configuration
    attr_accessor :domain, :client_id, :client_secret, :redirect_uri, :proxy, :encryption_key
  end

  class Client
    attr_accessor :request
    attr_accessor :response
    attr_accessor :access_token
    attr_accessor :error_message

    def initialize(access_token=nil)
      @settings = {
        base_url:      "https://#{Budgea.config.domain}/2.0",
        client_id:     Budgea.config.client_id,
        client_secret: Budgea.config.client_secret,
        proxy:         Budgea.config.proxy
      }
      # NOTE access_token is used only for limiting the scope of a request to the user only, because we could use the couple client_id/client_secret or manage_token to do all the request since it's all server side
      @access_token = access_token
    end

    def destroy_user
      if @access_token.present?
        @request = Typhoeus::Request.new(
          @settings[:base_url] + '/users/me',
          method:  :delete,
          proxy:   @settings[:proxy],
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

    def get_categories
      @request = Typhoeus::Request.new(
        @settings[:base_url] + '/categories',
        method:  :get,
        proxy:   @settings[:proxy],
        headers: { accept: :json },
        params:  authentification_params
      )
      run_and_parse_response 'categories'
    end

    def get_new_access_token(user_id)
      @request = Typhoeus::Request.new(
        @settings[:base_url] + "/users/#{user_id}/token",
        method:  :post,
        proxy:   @settings[:proxy],
        headers: headers,
        body:  { application: 'sharedAccess' }
      )
      run_and_parse_response
    end

    def delete_access_token
      @request = Typhoeus::Request.new(
        @settings[:base_url] + '/users/me/token',
        method:  :delete,
        proxy:   @settings[:proxy],
        headers: headers
      )
      @response = @request.run
      @response.code == 200
    end

    def get_all_accounts(connexion_id)
      @request = Typhoeus::Request.new(
        @settings[:base_url] + "/users/me/connections/#{connexion_id}/accounts?all",
        method:  :get,
        proxy:   @settings[:proxy],
        headers: headers
      )
      run_and_parse_response 'accounts'
    end

    def get_accounts ##used by transaction fetcher
      @request = Typhoeus::Request.new(
        @settings[:base_url] + '/users/me/accounts',
        method:  :get,
        proxy:   @settings[:proxy],
        headers: headers
      )
      run_and_parse_response 'accounts'
    end

    def get_transactions(account_id, min_date=nil, max_date=nil) ##used by transaction fetcher
      request_filters = "?min_date=#{min_date}&max_date=#{max_date}" if min_date.present? and max_date.present?
      @request = Typhoeus::Request.new(
        @settings[:base_url] + "/users/me/accounts/#{account_id}/transactions#{request_filters}",
        method:  :get,
        proxy:   @settings[:proxy],
        headers: headers
      )
      run_and_parse_response 'transactions'
    end

    def get_file(document_id)
      @request = Typhoeus::Request.new(
        @settings[:base_url] + "/users/me/documents/#{document_id}/file",
        method:  :get,
        proxy:   @settings[:proxy],
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

    def run_and_parse_response(collection_name=nil)
      @response = @request.run
      if @response.code.in? [200, 202, 204, 400, 403, 500, 503]
        result = JSON.parse(@response.body)
        @error_message = case result['code']
                         when 'wrongpass'
                           'Mot de passe incorrect.'
                         when 'websiteUnavailable'
                           'Site web indisponible.'
                         when 'bug'
                           'Service indisponible.'
                         when 'config'
                           result['description']
                         when 'actionNeeded'
                           'Veuillez confirmer les nouveaux termes et conditions.'
                         else
                           nil
                         end
        if result['message'] && result['message'].match(/Can't force synchronization of connection/)
          @error_message = 'Limite de synchronisation atteint.'
        end
        (collection_name && result[collection_name]) || result
      else
        @error_message = @response.body
      end
    end
  end

  class Errors
    class ServiceUnavailable < RuntimeError; end
  end
end
