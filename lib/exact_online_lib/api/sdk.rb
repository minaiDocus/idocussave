# -*- encoding : UTF-8 -*-
module ExactOnlineLib
  module Api
    class Sdk
      class << self
        def configure
          yield config
        end

        def config
          @config ||= Configuration.new
        end

        def connection
          Faraday.new(:url => @config.endpoint) do |f|
            f.response :logger
            f.request :oauth2, 'token', token_type: :bearer
            f.request :json
            f.adapter Faraday.default_adapter
          end
        end
      end

      class Configuration
        attr_accessor :endpoint, :client_id, :client_secret

        def initialize
          @endpoint = 'https://start.exactonline.fr'
        end
      end

      class Session
        attr_reader :access_token, :token_type, :expires_at, :refresh_token, :request, :response

        def initialize(options={})
          @config               = ExactOnlineLib::Api::Sdk.config.dup
          @config.client_id     = options[:client_id]
          @config.client_secret = options[:client_secret]

          @refresh_token = options[:refresh_token]
          @access_token  = options[:access_token]
          @expires_at    = options[:expires_at]
        end

        def get_authorize_url(redirect_uri=nil, force=false)

          Faraday.new(:url => "#{@config.endpoint}/api/oauth2/auth") do |f|
            f.response :logger
            f.request :oauth2, 'token', token_type: :bearer
            f.params = {
              client_id:     @config.client_id,
              redirect_uri:  redirect_uri,
              response_type: 'code',
              force_login:   (force ? '1' : '0')
            }
            f.use FaradayMiddleware::FollowRedirects
          end.get.env[:url].to_s
        end

        def get_access_token(code, redirect_uri=nil)
          @response = ExactOnlineLib::Api::Sdk.connection.post do |request|
            request.url "/api/oauth2/token"
            request.headers['Content-Type'] = 'application/json'
            request.body = {
              code:          code,
              grant_type:    'authorization_code',
              redirect_uri:  redirect_uri,
              client_id:     @config.client_id,
              client_secret: @config.client_secret
            }.to_json
          end

          if @response.status.to_i == 200
            data = JSON.parse @response.body
            @refresh_token = data['refresh_token']
            @access_token  = data['access_token']
            @expires_at    = Time.now + data['expires_in'].to_i.seconds
          else
            raise AuthError
          end
        end

        def refresh_tokens
          @response = ExactOnlineLib::Api::Sdk.connection.post do |request|
            request.url "/api/oauth2/token"
            request.headers['Content-Type'] = 'application/json'
            request.body = {
              refresh_token: @refresh_token,
              grant_type:    'refresh_token',
              client_id:     @config.client_id,
              client_secret: @config.client_secret
            }.to_json
          end

          if @response.status.to_i == 200
            data = JSON.parse @response.body
            @refresh_token = data['refresh_token']
            @access_token  = data['access_token']
            @expires_at    = Time.now + data['expires_in'].to_i.seconds
          else
            raise AuthError
          end
        end
      end

      # This is the error raised on Authentication failures.  Usually this means
      # one of three things
      # * Your user failed to go to the authorize url and approve your application
      # * You set an invalid or expired token and secret on your Session
      # * Your user deauthorized the application after you stored a valid token and secret
      class AuthError < RuntimeError
      end

      class Client
        attr_reader :request, :response, :current_division, :result_count

        def initialize(session, division=nil)
          @session = session
          @current_division = division
          @config = ExactOnlineLib::Api::Sdk.config.dup
        end

        def info(params=nil)
          result = do_http_get 'current/Me', nil, params
          if result.is_a? Array
            result.first
          else
            result
          end
        end

        def current_division
          if @current_division
            @current_division
          else
            result = do_http_get 'current/Me', nil, '$select' => 'CurrentDivision'
            @current_division = result.first['current_division']
          end
        end

        def divisions(division=current_division, params=nil)
          do_http_get 'system/Divisions', division, params
        end

        def users(division=current_division, params=nil)
          do_http_get 'users/Users', division, params
        end

        def accounts(division=current_division, params=nil)
          do_http_get 'crm/Accounts', division, params
        end

        def gl_accounts(division=current_division, params=nil)
          do_http_get 'financial/GLAccounts', division, params
        end

        def journals(division=current_division, params=nil)
          do_http_get 'financial/Journals', division, params
        end

        def periods(division=current_division, params=nil)
          do_http_get 'financial/FinancialPeriods', division, params
        end

        def transactions(division=current_division, params=nil)
          do_http_get 'financialtransaction/Transactions', division, params
        end

        def vat_codes(division=current_division, params=nil)
          do_http_get '/vat/VATCodes', division, params
        end

        def sales_entries(datas=nil, division=current_division, params=nil)
          do_http_post 'salesentry/SalesEntries', datas, division, params
        end

        def purchase_entries(datas=nil, division=current_division, params=nil)
          do_http_post 'purchaseentry/PurchaseEntries', datas, division, params
        end

      private

        def headers
          @headers ||= {
            authorization: "Bearer #{@session.access_token}",
            'Accept' => 'application/json',
            'Content-type' => 'application/json'
          }
        end

        def do_http_post(path, datas=nil, division=current_division, params=nil)
          url = "/api/v1/#{division}#{'/' if division}#{path}"
          @response = ExactOnlineLib::Api::Sdk.connection.post do |request|
            request.url url
            request.headers = headers
            request.body    = datas
          end
        end

        def do_http_get(path, division, params=nil)
          url = "/api/v1/#{division}#{'/' if division}#{path}"
          if params
            url += '?' + params.collect {|k, v|
              CGI.escape(k) + '=' + CGI.escape(v.to_s)
            }.join('&')
          end

          @response = ExactOnlineLib::Api::Sdk.connection.get do |request|
            request.url url
            request.headers = headers
          end

          parse_response
        end

        def parse_response
          if @response.status.in?([200, 201])
            data = JSON.parse @response.body
            @result_count = data['d']['__count'].try(:to_i) if data['d'].is_a? Hash
            _data = data['d'].is_a?(Array) ? data['d'] : data['d']['results']
            _data.map do |element|
              hsh = {}
              element.each do |k, v|
                hsh[k.underscore] = v
              end
              hsh.with_indifferent_access
            end
          else
            raise AuthError
          end
        end
      end
    end

  end
end
