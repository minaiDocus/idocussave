module Cedricom
  class Api
    CONFIG = YAML.load_file('config/cedricom.yml').freeze

    def initialize
      token = get_jwt

      @connection = Faraday.new(CONFIG['cedricom']['base_url']) do |faraday|
        faraday.response :logger
        faraday.adapter Faraday.default_adapter
        faraday.headers['Content-Type'] = "application/xml"
        faraday.headers['X-Auth-Token'] = token
      end
    end

    def get_reception_list(date = nil)
      path = "/sycomore/rest/comm/v1/abonnements/STR0834600/fr/*/receptions"

      path += "?dateTelechargement=#{date}" if date

      result = @connection.get do |request|
        request.url path
      end

      result.body
    end

    def get_reception(reception_id)
      path = "/sycomore/rest/comm/v1/abonnements/STR0834600/fr/*/receptions/#{reception_id}/fqr/*/fichier"

      result = @connection.get do |request|
        request.url path
      end

      if result.status == 200
        result.body
      else
        nil
      end
    end

    private

    def get_jwt
      @connection = Faraday.new(CONFIG['cedricom']['base_url']) do |faraday|
        faraday.response :logger
        faraday.adapter Faraday.default_adapter
        faraday.headers['Accept'] = "*/*"
        faraday.headers['Content-Type'] = "application/json"
        faraday.headers['X-Auth-Username'] = CONFIG['cedricom']['username']
        faraday.headers['X-Auth-Password'] = CONFIG['cedricom']['password']
      end

      result = @connection.post do |request|
        request.url "/sycomore/api/authent"
      end

      token = JSON.parse(result.body)["token"]
    end
  end
end