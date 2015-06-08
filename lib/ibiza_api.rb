# -*- encoding : UTF-8 -*-
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
        elsif k == 'piece_number'
          preseizure.piece_number
        elsif k == 'date' && preseizure[k]
          preseizure.date.in_time_zone('Paris').to_date.to_s
        else
          preseizure[k].presence
        end
      end.compact
      if results.empty?
        preseizure.third_party.presence || preseizure.operation_label
      else
        results.compact.join(separator)
      end
    end

    def self.piece_name(name, format, separator)
      data = name.split(' ')
      used_fields = format.select { |k,v| v['is_used'].to_i == 1 || v['is_used'] == true }
      sorted_used_fields = used_fields.sort { |(ak,av),(bk,bv)| av['position'] <=> bv['position'] }
      results = sorted_used_fields.map do |key,_|
        case key
        when 'code'    then data[0]
        when 'code_wp' then data[0].match('%') ? data[0].split('%')[1] : data[0]
        when 'journal' then data[1]
        when 'period'  then data[2]
        when 'number'  then data[3]
        else nil
        end
      end
      results.empty? ? name : results.compact.join(separator)
    end

    def self.to_import_xml(exercise, preseizures, fields = {}, separator = ' - ', piece_name_format = {}, piece_name_format_sep = ' ')
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.importEntryRequest {
          xml.importDate exercise.end_date
          xml.wsImportEntry {
            preseizures.each do |preseizure|
              preseizure.accounts.each do |account|
                xml.importEntry {
                  xml.journalRef preseizure.report.journal
                  xml.date computed_date(preseizure)
                  if preseizure.piece
                    xml.piece piece_name(preseizure.piece.name, piece_name_format, piece_name_format_sep)
                    xml.voucherID Settings.inner_url + preseizure.piece.get_access_url
                    xml.voucherRef preseizure.piece_number
                  end
                  xml.accountNumber account.number
                  xml.accountName account.number
                  xml.term computed_deadline_date(preseizure) if preseizure.deadline_date.present?
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

    # TODO refactor me
    def self.computed_date(preseizure)
      date = preseizure.date.try(:to_date)

      if preseizure.is_period_range_used
        out_of_period_range = date < preseizure.period_start_date || preseizure.period_end_date < date rescue true
      end

      if preseizure.is_period_range_used && out_of_period_range
        preseizure.period_start_date
      else
        date
      end
    end

    def self.computed_deadline_date(preseizure)
      if preseizure.deadline_date.present?
        date = computed_date(preseizure)
        result = preseizure.deadline_date < date ? date : preseizure.deadline_date
        result.to_date
      else
        nil
      end
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
          @original.parse_body(name)
        end
      end

      def original=(original)
        @original = original
        if original.headers['Content-Type'].present? && original.headers['Content-Type'].split(';')[0] == 'application/xml'
          hash = Hash.from_xml(original.body).first
          response = hash.last['response']
          @result = response['result']
          @datetime = response['datetime'].to_time
          if response['message'].present? && response['message'] != { 'i:nil' => 'true' }
            if @result == 'Error' && response['message']['error'].try(:[], 'number') && response['message']['error'].try(:[], 'description')
              @message = "Erreur n°#{response['message']['error']['number']} - #{response['message']['error']['description']}"
            else
              @message = response['message']
            end
          end
          if hash.last['data']
            @data_type = hash.last['data'].keys.last
            @data = hash.last['data'][@data_type]
            if @data.is_a? Hash
              @data = [@data]
            elsif !@data.is_a? Array
              @data = []
            end
          end
        else
          @result = @datetime = @message = @data_type = @data = nil
        end
      end

      def success?
        @result.try(:downcase) == 'success'
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
