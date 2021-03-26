# -*- encoding : UTF-8 -*-
module MyUnisoftLib
  class DataBuilder
    def initialize(preseizures)
      @preseizures    = preseizures
      @data_count     = 0
      @error_messages = []
    end

    def execute
      response = { data: data_content }

      response[:data_count] = @data_count
      response[:error_messages] = full_error_messages

      if full_error_messages.empty?
        response[:data_built] = true
      else
        response[:data_built] = false
      end

      response
    end

    private

    def data_content
      __data = []

      get_diary

      @preseizures.each do |preseizure|
        @data_count    += 1
        @preseizure     = preseizure
        piece2          = preseizure.piece.id
        payment_type_id = -1
        deadline        = preseizure.deadline_date
        debit           = 0
        credit          = 0

        entry    = preseizure.entries.first
        if entry.type == Pack::Report::Preseizure::Entry::DEBIT
          debit  = entry.amount
        else
          credit = entry.amount
        end

        label      = entry.number
        account_id = find_account(label)

        if account_id == 0
          @error_messages << { account: "Aucune correspondance du compte #{label} chez My Unisoft "}
        else
          __data << { "credit" => credit.to_f, "debit" => debit.to_f, "piece2" => piece2.to_s, "deadline" => deadline.to_s, "payment_type_id" => payment_type_id, "account_id" => account_id, "label" => label }
        end      
      end

      diary = find_diary_id

      if diary[:id] == 0
        @error_messages << { journal: "Aucune correspondance de journal #{diary[:preseizure_code]} chez My Unisoft"}
      elsif __data.size == @preseizures.size
        '{"pj_list": [{"name": "' + @preseizures.first.piece.name + '", "type": "application/pdf", "content": "' + Base64.encode64(File.read(@preseizures.first.piece.cloud_content_object.path)) + '"}], "entry_list": ' + __data.to_json + ', "date_piece": "' + Time.now.strftime("%Y-%m-%d") + '", "period_to": "' + Time.now.strftime("%Y-%m-%d") + '", "period_from": "' + Time.now.strftime("%Y-%m-%d") + '", "diary_id": "' + diary[:id].to_s + '", "etablissement_id": "' + @preseizures.first.user.my_unisoft.society_id.to_s + '" }'
      end
    end

    def client
      @client ||= MyUnisoftLib::Api::Client.new(@preseizures.first.user.my_unisoft.api_token)
    end

    def get_diary
      @diary ||= client.get_diary(@preseizures.first.user.my_unisoft.society_id)
    end

    def find_diary_id
      diary_id            = 0
      preseizure_code     = @preseizures.first.user.account_book_types.where(name: @preseizures.first.journal_name).first.try(:pseudonym)

      get_diary.each do |diary|
        diary_id = diary['diary_id'] if diary['code'] == preseizure_code
      end

      { id: diary_id, preseizure_code: preseizure_code }
    end

    def get_account
      @accounts ||= client.get_account(@preseizure.user.my_unisoft.society_id)

      account = @accounts[:status] == "success" ? @accounts[:body] : []

      account['account_array']
    end

    def find_account(label)
      account_id = 0

      get_account.each do |account|
        account_id = account['account_id'] if account['label'].strip == label.strip
      end

      account_id
    end

    def full_error_messages
      @error_messages.join(',')
    end
  end
end