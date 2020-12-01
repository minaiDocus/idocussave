module MyUnisoftLib
  module Api
    class Client
      attr_accessor :request, :settings

      def initialize(access_token=nil)
        @settings = {
                      base_api_url:           MyUnisoftLib::Api::Util.config.base_api_url,
                      base_user_url:          MyUnisoftLib::Api::Util.config.base_user_url,
                      member_group_id:        MyUnisoftLib::Api::Util.config.member_group_id,
                      granted_for:            MyUnisoftLib::Api::Util.config.granted_for,
                      target:                 MyUnisoftLib::Api::Util.config.target,
                      x_third_party_secret:   MyUnisoftLib::Api::Util.config.x_third_party_secret,
                      user_token:             MyUnisoftLib::Api::Util.config.user_token
                    }

        @access_token = access_token
      end

      ##### FOR DEV #####

      def get_member_group_id(mail='mina@idocus.com')
        @response = connection.get do |request|
          request.url "/api/group?mail=#{mail}"
        end

        json_parse
      end

      def get_user_token(mail='mina@idocus.com', password='RirudE')
        body = '{ "member_group_id": ' + @settings[:member_group_id].to_s + ', "password": "' + password + '", "mail": "' + mail + '", "grant_type": "password" }'

        @response = connection.post do |request|
          request.url '/api/auth/token'
          request.headers = { "X-Third-Party-Secret" => "{#{@settings[:x_third_party_secret]}}", "Content-Type" => "application/octet-stream" }
          request.body = body
        end

        json_parse
      end

      def get_granted_for
        @response = connection_bearer.post do |request|
          request.url "api/v1/key/granted-for"
          request.headers = { "Authorization" => "Bearer #{@access_token}"}
          request.body = { "secret": "#{@settings[:x_third_party_secret]}" }.to_query
        end

        json_parse
      end

      def generate_api_token
        @response = connection_bearer.post do |request|
          request.url '/api/v1/key/create'
          request.headers = { "Authorization" => "Bearer #{@access_token}"}
          request.body = { grantedFor: @settings[:granted_for], target: @settings[:target] }.to_query
        end

        json_parse
      end

      ##### FOR DEV #####

      def get_routes
        @response = connection.get do |request|
          request.url "api/v1/key/info"
          request.headers = { "Authorization" => "Bearer #{@access_token}"}
        end

        json_parse
      end

      def get_account(id)
        @response = connection.get do |request|
          request.url "api/v1/account"
          request.headers = { "Authorization" => "Bearer #{@access_token}", "X-Third-Party-Secret" => "#{@settings[:x_third_party_secret]}" }
          request.params = { "mode" => "2", "society_id" => "#{id}" }
        end

        json_parse
      end

      def get_society_info
        @response = connection.get do |request|
          request.url "api/v1/society"
          request.headers = { "Authorization" => "Bearer #{@access_token}", "X-Third-Party-Secret" => "#{@settings[:x_third_party_secret]}", "Content-Type" => "application/octet-stream" }
        end

        json_parse
      end

      def get_diary(id)
        @response = connection.get do |request|
          request.url "api/v1/diary?society-id=#{id}"
          request.headers = { "Authorization" => "Bearer #{@access_token}", "X-Third-Party-Secret" => "#{@settings[:x_third_party_secret]}", "Content-Type" => "application/octet-stream" }
        end

        JSON.parse @response.body
      end

      def send_pre_assignment(data_path="")
        data = JSON.parse(File.read(data_path).to_json)

        @response = connection.post do |request|
          request.url "api/v1/entry/temp"
          request.headers = { "Authorization" => "Bearer #{@access_token}", "X-Third-Party-Secret" => "#{@settings[:x_third_party_secret]}", "Content-Type" => "application/json" }
          request.body = data
        end

        JSON.parse @response.body
      end

      private

      def connection_bearer
        Faraday.new(:url => @settings[:base_api_url]) do |f|
          f.response :logger
          f.request :oauth2, 'token', token_type: :bearer
          f.adapter Faraday.default_adapter
        end
      end

      def connection
        Faraday.new(:url => @settings[:base_api_url], :ssl => {:verify => false}) do |f|
          f.response :logger
          f.adapter Faraday.default_adapter
        end
      end

      def json_parse
        if @response.status == 200
          { status: "success", body: JSON.parse(@response.body) }
        else
          { status: "error", body: JSON.parse(@response.body) }
        end
      end
    end
  end
end