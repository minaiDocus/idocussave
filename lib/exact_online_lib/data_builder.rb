module ExactOnlineLib
  class DataBuilder
    def initialize(delivery)
      @preseizures    = delivery.preseizures
      @organization   = delivery.organization
      @user           = delivery.user
      @journal        = nil
      @error_messages  = []
    end

    def execute
      if valid?
        response = { data_built: true }
        response[:data] = {
                            header: {
                                      "type": journal['type']
                                    },
                            payload: payload
                          }.to_json.to_s
      else
        response = { data_built: false, data: nil, error_messages: full_error_messages }
      end

      response
    end

    private

    def exact_online_data
      @exact_online_data ||= ExactOnlineLib::Data.new(@user)
    end

    def valid?
      @error_messages << 'Journal Exact Online introuvable' unless journal.present?
      if journal.present?
        @error_messages << "Journal Type invalide (#{journal['type']}) - doit être de type vente ou achat" unless ['20', '22'].include?(journal['type'].to_s)
      end

      @error_messages.empty?
    end

    def full_error_messages
      @error_messages.join(',')
    end

    def journal
      return @journal if @journal

      journals     = exact_online_data.journals
      journal_name = @preseizures.first.journal_name.try(:downcase)

      j = journals.select{ |j| j['description'].downcase == journal_name || j['code'].downcase == journal_name }.first
      @journal = j || []
    end

    def third_party_of(preseizure)
      unless @accounts
        @accounts = exact_online_data.accounts
      end

      Rails.cache.fetch ['third_party_of', preseizure.id], expires_in: 2.minutes do
        number  = preseizure.accounts.ttc.first.number.try(:strip).try(:downcase)
        account = @accounts.select{ |a| a['code'].try(:strip).try(:downcase) == number }.first
        account.present? ? account['id'] : nil
      end
    end

    def conterpart_account_of(account_target)
      unless @gl_accounts
        @gl_accounts = exact_online_data.gl_accounts
      end

      Rails.cache.fetch ['conterpart_account_of', account_target.id], expires_in: 2.minutes do
        number  = account_target.number.try(:strip).try(:downcase)
        account = @gl_accounts.select{ |a| a['code'].try(:strip).try(:downcase) == number }.first
        account.present? ? account['id'] : nil
      end
    end

    def vat_code_of(entry)
      entry.account.try(:number).try(:strip) || 0
    end

    def computed_date_of(preseizure)
      date = preseizure.date.try(:to_date)

      if preseizure.is_period_range_used
        out_of_period_range = begin
                                date < preseizure.period_start_date || preseizure.period_end_date < date
                              rescue
                                true
                              end
      end

      result = if (preseizure.is_period_range_used && out_of_period_range) || date.nil?
                 preseizure.period_start_date
               else
                 date
               end
    end

    def preseizure_entries(preseizure)
      entries = []
      amount_ttc = preseizure.accounts.ttc.first.entries.first.amount

      preseizure.entries.each do |entry|
        account = entry.account
        next if account.type == Pack::Report::Preseizure::Account::TVA

        conterpart_account = conterpart_account_of(account)
        next unless conterpart_account.present?

        if account.type == Pack::Report::Preseizure::Account::TTC
          vat_code = 0
        else
          vat_entry = preseizure.entries.where("type = '#{entry.type}' AND number = '#{entry.number}' AND id != '#{entry.id}'").first
          vat_code  = vat_entry.account.try(:number).try(:strip) || 0
        end

        entries <<  {
                      AmountFC:  entry.amount,
                      GLAccount: conterpart_account,
                      VATCode:   vat_code
                    }
      end

      entries
    end

    def payload
      if journal['type'] == 20
        entryTarget = 'Customer'
        entryType   = 'SalesEntryLines'
      else
        entryTarget = 'Supplier'
        entryType   = 'PurchaseEntryLines'
      end

      @preseizures.map do |preseizure|
        {
          "preseizure_id":    preseizure.id,
          "#{entryTarget}":   third_party_of(preseizure),
          "Journal":          journal['code'],
          "EntryDate":        computed_date_of(preseizure),
          "#{entryType}":     preseizure_entries(preseizure)
        }
      end
    end

  end

end
