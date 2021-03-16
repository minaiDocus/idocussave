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
      config.user_token     = new_config['user_token']      if new_config['user_token']
      config.redirect_uri   = new_config['redirect_uri']    if new_config['redirect_uri']
      config.encryption_key = new_config['encryption_key']  if new_config['encryption_key']
      config.proxy          = new_config['proxy']           if new_config['proxy']
    end
  end

  class Configuration
    attr_accessor :domain, :client_id, :client_secret, :user_token, :redirect_uri, :proxy, :encryption_key
  end

  class Client
    attr_accessor :request
    attr_accessor :response
    attr_accessor :access_token
    attr_accessor :error_message

    def initialize(access_token=nil)
      @settings = {
        base_url:      "https://#{Budgea.config.domain}",
        client_id:     Budgea.config.client_id,
        client_secret: Budgea.config.client_secret,
        user_token:    Budgea.config.user_token,
        proxy:         Budgea.config.proxy
      }
      # NOTE access_token is used only for limiting the scope of a request to the user only, because we could use the couple client_id/client_secret or manage_token to do all the request since it's all server side
      @access_token = access_token
    end

    def destroy_user
      if @access_token.present?
        @response = connection.delete do |request|
          request.url "/2.0/users/me"
          request.headers = headers
        end

        if @response.status.to_i == 200
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
      @response = connection.get do |request|
        request.url '/2.0/categories'
        request.headers['Accept'] = 'application/json'
        request.body = authentification_params.to_query
      end

      run_and_parse_response 'categories'
    end

    def get_new_access_token(user_id)
      @response = connection.post do |request|
        request.url "/2.0/users/#{user_id}/token"
        request.headers = headers
        request.body = '{ application: "sharedAccess" }'
      end

      run_and_parse_response
    end

    def renew_access_token(user_id)
      return { 'jwt_token' => nil } if Rails.env != 'production' && @settings[:base_url].match(/idocus[.]biapi[.]pro/) #IMPORTANT: secure jwt token execution for non production environment

      @response = connection.post do |request|
        request.url "/2.0/auth/jwt"
        request.headers['Accept'] = 'application/json'
        request.body = authentification_params.merge({ id_user: user_id, expire: false }).to_query
      end

      run_and_parse_response
    end

    def delete_access_token
      @response = connection.delete do |request|
        request.url '/2.0/users/me/token'
        request.headers = headers
      end

      @response.status.to_i == 200
    end

    def get_all_accounts(connexion_id)
      @response = connection.get do |request|
        request.url "/2.0/users/me/connections/#{connexion_id}/accounts?all"
        request.headers = headers
      end

      run_and_parse_response 'accounts'
    end

    def get_accounts ##used by transaction fetcher
      @response = connection.get do |request|
        request.url "/2.0/users/me/accounts"
        request.headers = headers
      end

      run_and_parse_response 'accounts'
    end

    def get_transactions(account_id, min_date=nil, max_date=nil) ##used by transaction fetcher
      request_filters = "?min_date=#{min_date}&max_date=#{max_date}" if min_date.present? and max_date.present?

      @response = connection.get do |request|
        request.url "/2.0/users/me/accounts/#{account_id}/transactions#{request_filters}"
        request.headers = headers
      end

      run_and_parse_response 'transactions'
    end


    def get_documents(connection_id, min_date=nil, max_date=nil) ##used by transaction fetcher
      request_filters = "?min_date=#{min_date}&max_date=#{max_date}" if min_date.present? and max_date.present?

      @response = connection.get do |request|
        request.url "/2.0/users/me/connections/#{connection_id}/documents#{request_filters}"
        request.headers = headers
      end

      run_and_parse_response 'documents'
    end

    def get_file(document_id)
      @response = connection.get do |request|
        request.url "/2.0/users/me/documents/#{document_id}/file"
        request.headers = headers
      end

      if @response.status.to_i == 200
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

    def get_all_connections
      @response = connection.get do |request|
        request.url "/2.0/users/me/connections"
        request.headers = headers
      end

      run_and_parse_response
    end

    def get_all_users(search=nil)
      _last_token = @access_token
      @access_token = @settings[:user_token] # Token for listing all users

      @response = connection.get do |request|
        request.url "/2.0/users"
        request.headers = headers
      end

      @access_token = _last_token
      run_and_parse_response
    end

    def get_connections_log(id, min_date=nil, max_date=nil, limit=nil, offset=nil,  state=nil, period=nil, id_user=nil, id_source=nil)
      request_filters = ''
      request_filters +=  "?min_date=#{min_date}&max_date=#{max_date}" if min_date.present? && max_date.present?
      request_filters += "&limit=#{limit}"          if limit.present?
      request_filters += "&offset=#{offset}"        if offset.present?
      request_filters += "&state=#{state}"          if state.present?
      request_filters += "&period=#{period}"        if period.present?
      request_filters += "&id_user=#{id_user}"      if id_user.present?
      request_filters += "&id_source=#{id_source}"  if id_source.present?

      @response = connection.get do |request|
        request.url "/2.0/users/me/connections/#{id}/logs#{request_filters}"
        request.headers = headers
      end

      run_and_parse_response
    end

    def delete_connection(id)
      @response = connection.delete do |request|
        request.url "/2.0/users/me/connections/#{id}"
        request.headers = headers
      end

      if @response.status.to_i == 200
        @access_token = nil
        true
      else
        false
      end
    end

    def resume_connexion(retriever, force_resume = false)
      if retriever.budgea_id.present?

        last_log = get_connections_log(retriever.budgea_id).try(:[], 'connectionlogs').try(:first) unless force_resume

        if !force_resume && last_log.present?
          last_log.merge!({"source"=> "ProcessRetrievedData", "id"=> retriever.budgea_id})
          retriever.update_state_with(last_log.with_indifferent_access)

          { from: 'last_log', response: last_log }
        else
          @response = connection.post do |request|
            request.url "/2.0/users/me/connections/#{retriever.budgea_id}"
            request.body = { resume: true }.to_query
            request.headers = headers
          end

          if @response.status.in? [200, 202, 204, 400, 403, 500, 503]
            connections = JSON.parse(@response.body)

            connections = connections['connections'] if connections['connections'].present?

            connections.merge!({"source"=> "ProcessRetrievedData", "id"=> retriever.budgea_id})

            retriever.update_state_with(connections.with_indifferent_access)
          end

          { from: 'resume', response: @response.body }
        end
      end
    end

    def get_public_key
      @response = connection.get do |request|
        request.url "/2.0/publickey"
        request.headers['Accept'] = 'application/json'
        request.body = authentification_params
      end

      p run_and_parse_response
    end

  private
    def connection
      Faraday.new(:url => @settings[:base_url]) do |f|
        f.response :logger
        f.request :oauth2, 'token', token_type: :bearer
        f.adapter Faraday.default_adapter
        f.proxy = @settings[:proxy]
      end
    end

    def headers
      {
        'Accept' => 'application/json',
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
      return @error_message = 'Service indisponible...' if @response.nil?

      if @response.status.in? [200, 202, 204, 400, 403, 500, 503]
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