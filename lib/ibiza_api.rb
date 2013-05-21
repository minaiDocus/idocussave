module IbizaAPI
  class Client < Struct.new(:token)
    def request(path)
      url = File.join(IbizaAPI::Config::ROOT_URL, path)
      uri = URI(URI.escape(url))
      request = Net::HTTP::Get.new uri.request_uri
      request.add_field 'partnerID', IbizaAPI::Config::PARTNER_ID
      request.add_field 'irfToken', self.token

      begin
        response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
          http.request(request)
        end
        if response.is_a?(Net::HTTPSuccess)
          response.body
        else
          response
        end
      rescue Timeout::Error,
          Errno::ECONNRESET,
          EOFError,
          Net::HTTPBadResponse,
          Net::HTTPHeaderSyntaxError,
          Net::ProtocolError => e
        e
      end
    end

    def parse_result(body)
      data = OpenStruct.new

      doc = Nokogiri::XML(body)
      data.datetime = doc.css('datetime').first.try(:text)
      data.result   = doc.css('result').first.try(:text)
      data.message  = doc.css('message').first.try(:text)

      if data.result == 'Success'
        data.company = []
        doc.css('wsPracticeDatabase').each do |e|
          id = e.children.css('database').first.try(:text)
          name = e.children.css('name').first.try(:text)
          data.company << { id: id, name: name }
        end

        data.accounts = []
        doc.css('wsAccounts').each do |e|
          account = {}
          account['associate']        = e.children.css('associate').first.try(:text)
          account['auditable']        = e.children.css('auditable').first.try(:text)
          account['bankReconcilable'] = e.children.css('bankReconcilable').first.try(:text)
          account['category']         = e.children.css('category').first.try(:text)
          account['centralisable']    = e.children.css('centralisable').first.try(:text)
          account['closed']           = e.children.css('closed').first.try(:text)
          account['collectif']        = e.children.css('collectif').first.try(:text)
          account['name']             = e.children.css('name').first.try(:text)
          account['number']           = e.children.css('number').first.try(:text)
          account['reconcilable']     = e.children.css('reconcilable').first.try(:text)
          data.accounts << account
        end
      end
      data
    end

    def company
      result = raw_company
      result.is_a?(String) ? parse_result(result) : result
    end

    def raw_company
      request(IbizaAPI::Config::COMPANY_PATH)
    end

    def accounts(id, filter_field=nil, filter_value=nil)
      result = raw_accounts(id, filter_field, filter_value)
      result.is_a?(String) ? parse_result(result) : result
    end

    def raw_accounts(id, filter_field=nil, filter_value=nil)
      path = File.join(
                        [
                          IbizaAPI::Config::COMPANY_PATH,
                          id,
                          IbizaAPI::Config::ACCOUNTS_PATH,
                          filter_field,
                          filter_value
                        ].compact
                      )
      request(path)
    end
  end
end