class SlimpayCheckout
  class << self
    def configure
      yield config
    end

    def config
      @config ||= Configuration.new
    end

    def config=(new_config)
      config.app_id       = new_config['app_id']        if new_config['app_id']
      config.app_secret   = new_config['app_secret']    if new_config['app_secret']
      config.app_base_uri = new_config['app_base_uri']  if new_config['app_base_uri']
      config.app_creditor = new_config['app_creditor']  if new_config['app_creditor']
    end

    def connection(url)
      Faraday.new(:url => url) do |f|
        f.response :logger
        f.request :oauth2, 'token', token_type: :bearer
        f.request :json
        f.adapter Faraday.default_adapter
      end
    end
  end

  class Configuration
    attr_accessor :app_id, :app_secret, :app_base_uri, :app_creditor
  end

  class Client
    attr_accessor :request
    attr_accessor :response
    attr_accessor :error_message
    attr_accessor :order_reference
    attr_accessor :mandate
    attr_accessor :bank_account
    attr_accessor :auth_token

    def initialize
      @settings = {
        base_uri:   SlimpayCheckout.config.app_base_uri.strip,
        app_id:     SlimpayCheckout.config.app_id.strip,
        app_secret: SlimpayCheckout.config.app_secret.strip,
        app_creditor: SlimpayCheckout.config.app_creditor.strip,
      }

      @auth_token = {}
      @order_reference = nil
      @mandate = nil
    end

    def get_base_links
      @response = SlimpayCheckout.connection(@settings[:base_url]).get do |request|
        request.headers = {
                    'Accept' => 'application/hal+json; profile="https://api.slimpay.net/alps/v1"',
                    'Authorization' => "Bearer #{@auth_token['access_token']}"
                  }
      end

      @links = run_and_parse_response '_links'
    end

    def create_sepa_order(debit_mandate)
      check_auth_token

      link_target = 'https://api.slimpay.net/alps#create-orders'
      url = @links[link_target]['href']

      @response = SlimpayCheckout.connection(url).post do |request|
        request.headers = {
                    'Accept' => 'application/hal+json; profile="https://api.slimpay.net/alps/v1"',
                    'Authorization' => "Bearer #{@auth_token['access_token']}",
                    'Content-Type' => "application/json"
                  }
        request.body = {
                'started' => true,
                'locale'  => nil,
                'paymentScheme' => 'SEPA.DIRECT_DEBIT.CORE',
                'creditor' => { 'reference' =>  @settings[:app_creditor] },
                'subscriber' => { 'reference' => debit_mandate.clientReference },
                'items' => [
                  {
                    'type' => 'signMandate',
                    'action' => 'sign',
                    'mandate' => {
                      'reference' => nil,
                      'signatory' => {
                        'honorificPrefix' => debit_mandate.title.capitalize,
                        'givenName' => debit_mandate.firstName,
                        'familyName' => debit_mandate.lastName,
                        'email' => debit_mandate.email,
                        'telephone' => nil,
                        'companyName' => debit_mandate.companyName,
                        'organizationName' => nil,
                        'billingAddress' => {
                            'street1' => debit_mandate.invoiceLine1,
                            'street2' => debit_mandate.invoiceLine2,
                            'city' => debit_mandate.invoiceCity,
                            'postalCode' => debit_mandate.invoicePostalCode,
                            'country' => debit_mandate.invoiceCountry
                        }
                      }
                    }
                  }
                ]
              }.to_json
      end

      @order_reference = run_and_parse_response
    end

    # def update_sepa_order(debit_mandate)
    #   check_auth_token

    #   link_target = 'https://api.slimpay.net/alps#create-orders'

    #   @request = Typhoeus::Request.new(
    #     @links[link_target]['href'],
    #     method:  :post,
    #     headers:  {
    #                 'Accept' => 'application/hal+json; profile="https://api.slimpay.net/alps/v1"',
    #                 'Authorization' => "Bearer #{@auth_token['access_token']}",
    #                 'Content-Type' => "application/json"
    #               },
    #     body: {
    #             'started' => true,
    #             'locale'  => nil,
    #             'creditor' => { 'reference' =>  @settings[:app_creditor] },
    #             'subscriber' => { 'reference' => debit_mandate.clientReference },
    #             'items' => [
    #               {
    #                 'type' => 'signMandate',
    #                 'action' => 'amendBankAccount',
    #                 'mandate' => {
    #                   'reference' => debit_mandate.reference
    #                 }
    #               }
    #             ]
    #           }.to_json
    #   )

    #   @order_reference = run_and_parse_response
    # end

    def create_card_order(client_reference)
      check_auth_token

      link_target = 'https://api.slimpay.net/alps#create-orders'
      url = @links[link_target]['href']

      @response = SlimpayCheckout.connection(url).post do |request|
        request.headers = {
                    'Accept' => 'application/hal+json; profile="https://api.slimpay.net/alps/v1"',
                    'Authorization' => "Bearer #{@auth_token['access_token']}",
                    'Content-Type' => "application/json"
                  }
        request.body = {
                'started' => true,
                'locale'  => nil,
                'paymentScheme' => 'CARD',
                'creditor' => { 'reference' =>  @settings[:app_creditor] },
                'subscriber' => { 'reference' => client_reference },
                'items' => [ { 'type' => 'cardAlias' } ]
              }.to_json
      end

      @order_reference = run_and_parse_response
    end

    def get_checkout_frame
      raise Errors::NotAllowed.new('No order set') if !@order_reference.present? || @order_reference['state'] == 'closed.completed'

      check_auth_token

      link_target = 'https://api.slimpay.net/alps#extended-user-approval'

      url = @order_reference['_links'][link_target]['href'].gsub('{?mode}', '')

      @response = SlimpayCheckout.connection(url).get do |request|
        request.url '?mode=iframeembedded'
        request.headers = {
                    'Accept' => 'application/hal+json; profile="https://api.slimpay.net/alps/v1"',
                    'Authorization' => "Bearer #{@auth_token['access_token']}",
                    'Content-Type' => "application/json"
                  }
      end

      content_64 = run_and_parse_response 'content'

      unless @error_message
        content_64
      else
        raise Errors::NotAllowed.new @error_message
      end
    end

    def get_checkout_uri_redirection
      raise Errors::NotAllowed.new('No order set') if !@order_reference.present? || @order_reference['state'] == 'closed.completed'
      link_target = 'https://api.slimpay.net/alps#user-approval'

      @order_reference['_links'][link_target]['href']
    end

    def get_order(debit_mandate)
      check_auth_token

      link_target = 'https://api.slimpay.net/alps#get-orders'
      url = @links[link_target]['href'].gsub('{?creditorReference,reference}', '')

      @response = SlimpayCheckout.connection(url).get do |request|
        request.url '?creditorReference='+@settings[:app_creditor]+'&reference='+debit_mandate.reference
        request.headers = {
                    'Accept' => 'application/hal+json; profile="https://api.slimpay.net/alps/v1"',
                    'Authorization' => "Bearer #{@auth_token['access_token']}",
                    'Content-Type' => "application/json"
                  }
      end

      @order_reference = run_and_parse_response
    end

    def get_mandate
      raise Errors::NotAllowed.new('No order completed fetched') if !@order_reference.present? || @order_reference['state'] != 'closed.completed'

      check_auth_token

      link_target = 'https://api.slimpay.net/alps#get-mandate'
      url = @order_reference['_links'][link_target]['href']

      @response = SlimpayCheckout.connection(url).get do |request|
        request.headers = {
                    'Accept' => 'application/hal+json; profile="https://api.slimpay.net/alps/v1"',
                    'Authorization' => "Bearer #{@auth_token['access_token']}",
                    'Content-Type' => "application/json"
                  }
      end

      @mandate = run_and_parse_response
    end

    def revoke_mandate
      raise Errors::NotAllowed.new('No order fetched') if !@mandate.present? || @mandate['state'] != 'active'

      check_auth_token

      link_target = 'https://api.slimpay.net/alps#revoke-mandate'
      url = @mandate['_links'][link_target]['href']

      @response = SlimpayCheckout.connection(url).post do |request|
        request.headers = {
                    'Accept' => 'application/hal+json; profile="https://api.slimpay.net/alps/v1"',
                    'Authorization' => "Bearer #{@auth_token['access_token']}",
                    'Content-Type' => "application/json"
                  }
      end

      @mandate = run_and_parse_response
    end

    def get_bank_account
      raise Errors::NotAllowed.new('No mandate fetched') if !@mandate.present? || @mandate['state'] != 'active'

      check_auth_token

      link_target = 'https://api.slimpay.net/alps#get-bank-account'

      url = @mandate['_links'][link_target]['href']

      @response = SlimpayCheckout.connection(url).get do |request|
        request.headers = {
                    'Accept' => 'application/hal+json; profile="https://api.slimpay.net/alps/v1"',
                    'Authorization' => "Bearer #{@auth_token['access_token']}",
                    'Content-Type' => "application/json"
                  }
      end

      @bank_account = run_and_parse_response
    end

  private

    def check_auth_token
      ##TODO: find a better way to check token expired time
      return true if @auth_token.try(:[], 'access_token').present?

      auth_hash = Base64.strict_encode64("#{@settings[:app_id]}:#{@settings[:app_secret]}").strip

      @response = SlimpayCheckout.connection(@settings[:base_url]).post do |request|
        request.url '/oauth/token'
        request.headers = {
                    'Accept' => 'application/json',
                    'Authorization' => "Basic #{auth_hash}",
                    'Content-Type' => "application/x-www-form-urlencoded"
                  }
        request.body = { grant_type: 'client_credentials', scope: 'api' }.to_json
      end

      if @response.status.to_i == 200
        @auth_token = JSON.parse(@response.body)

        get_base_links
      else
        raise Errors::ServiceUnavailable.new JSON.parse(@response.body)['message']
      end
    end

    def run_and_parse_response(collection_name=nil)
      @error_message = nil

      result = JSON.parse(@response.body) if @response.body.present?

      if @response.status.in? [200, 201]
        (collection_name && result[collection_name]) || result
      else
        @error_message = result.try(:[], 'message') || 'An error occured'
        raise Errors::ServiceUnavailable.new @error_message
      end
    end
  end

  class Errors
    class ServiceUnavailable < RuntimeError; end
    class NotAllowed < RuntimeError; end
  end
end
