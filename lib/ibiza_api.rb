module IbizaAPI
  class Utils
    def self.description(preseizure, fields, separator)
      used_fields = fields.select { |k,v| v['is_used'].to_i == 1 || v['is_used'] == true }
      sorted_used_fields = used_fields.sort { |(ak,av),(bk,bv)| av['position'] <=> bv['position'] }
      results = sorted_used_fields.map do |k,_|
        if k == 'journal'
          preseizure.report.journal
        elsif k == 'piece_name' && preseizure.piece
          preseizure.piece.name
        else
          preseizure[k].presence
        end
      end
      if results.empty?
        preseizure.third_party
      else
        results.compact.join(separator)
      end
    end

    def self.to_import_xml(period_end_date, preseizures, fields = {}, separator = ' - ')
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.importEntryRequest {
          xml.importDate period_end_date
          xml.wsImportEntry {
            preseizures.each do |preseizure|
              preseizure.accounts.each do |account|
                xml.importEntry {
                  xml.journalRef preseizure.report.journal
                  result = preseizure.date < preseizure.period_date || preseizure.date > preseizure.end_period_date rescue true
                  if result
                    xml.date preseizure.period_date.to_date
                  else
                    xml.date preseizure.date.to_date
                  end
                  if preseizure.piece
                    xml.piece preseizure.piece.name
                    xml.voucherID SITE_INNER_URL + preseizure.piece.get_access_url
                    xml.voucherRef preseizure.piece_number
                  end
                  xml.accountNumber account.number
                  xml.accountName preseizure.third_party
                  xml.description description(preseizure, fields, separator)
                  if account.entries.first.type == Pack::Report::Preseizure::Entry::DEBIT
                    xml.debit account.entries.first.amount
                  else
                    xml.credit account.entries.first.amount
                  end
                }
              end
            end
          }
        }
      end
      builder.to_xml
    end
  end

  class Client
    class Request #:nodoc:
      attr_accessor :client, :path, :method, :body, :original

      def initialize(client)
        @client = client
        @path = ''
        @method = :get
        @body = ''
      end
      
      def <<(path)
        @path << "/#{path}"
      end
      
      def path?
        @path.length > 0
      end
    
      def url
        "#{base}#{@path}"
      end

      def base
        IbizaAPI::Config::ROOT_URL
      end

      def clear
        @method = :get
        @path = ''
      end

      def run
        @original = Typhoeus::Request.new(
          url,
          method:  @method,
          body:    @body,
          headers: {
                      'content-type' => 'application/xml',
                      irfToken: @client.token,
                      partnerID: @client.partner_id
                    }
        )
        @client.response.original = @original.run
        @client.response.result || @client.response.code
      end
    end

    class Response
      attr_accessor :original, :result, :datetime, :message, :data_type, :data

      def method_missing name, *args
        begin
          @original.send(name, *args)
        rescue NoMethodError
          parse_body(name)
        end
      end

      def original=(original)
        @original = original
        if original.headers['Content-Type'].split(';')[0] == 'application/xml'
          hash = Hash.from_xml(original.body).first
          response = hash.last['response']
          @result = response['result']
          @datetime = response['datetime'].to_time
          @message = response['message'].gsub('&lt;','<').gsub('&gt;','>') if response['message'].present?
          if hash.last['data']
            @data_type, @data = hash.last['data'].first
            @data = [@data] if @data.is_a? Hash
          end
        else
          @result = @datetime = @message = @data_type = @data = nil
        end
      end

      def success?
        @result.downcase == 'success'
      end
    end

    attr_accessor :token, :partner_id, :request, :response

    def initialize(token)
      @token = token
      @partner_id = IbizaAPI::Config::PARTNER_ID
      @request = Request.new(self)
      @response = Response.new
    end

    def method_missing(name, *args)
      append(name, *args)
    end

    def append(name, *args)
      name = name.to_s
      if name.to_s =~ /^(.*)(!|\?)$/
        @request << $1
        if args.any?
          if $2 == '!'
            @request.body = args.first
          else
            args.each do |arg|
              @request << arg
            end
          end
        end
        @request.method = $2 == '!' ? :post : :get
        return @request.run
      else
        @request << name
        if args.any?
          args.each do |arg|
            @request << arg
          end
        end
        self
      end
    end
  end
end