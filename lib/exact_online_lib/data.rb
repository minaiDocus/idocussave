# -*- encoding : UTF-8 -*-
module ExactOnlineLib
  class Data
    def initialize(user)
      @user         = user
      @organization = user.organization
      @exact_online = user.exact_online
    end

    def division
      @division ||= client.current_division
    end

    def accounts
      @accounts ||= get_list :accounts, division, '$inlinecount' => 'allpages', '$orderby' => 'Code'
    end

    def gl_accounts
      @gl_accounts ||= get_list :gl_accounts, division, '$inlinecount' => 'allpages', '$orderby' => 'Code'
    end

    def vat_codes
      @vat_codes ||= get_list :vat_codes, division, '$inlinecount' => 'allpages', '$orderby' => 'Code'
    end

    def journals
      @journals ||= get_list :journals, division, {
          '$inlinecount' => 'allpages',
          '$orderby'     => 'Code',
          '$select'      => 'Code,Description,Type'
        }
    end

    def accounting_plans
      @accounting_plans ||= accounts.map do |account|
        provider_account = gl_accounts.select { |e| e['id'] == account['gl_account_purchase'] }.first.try(:[], 'code')
        customer_account = gl_accounts.select { |e| e['id'] == account['gl_account_sales'] }.first.try(:[], 'code')

        data = []
        if provider_account
          vat_info = vat_codes.select { |e| e['code'].try(:strip).try(:downcase) == account['purchase_vat_code'].try(:strip).try(:downcase) }.first
          data << {
            name:        account['name'],
            number:      account['code'].try(:strip).try(:downcase),
            vat:         { code: vat_info.try(:[], 'code').try(:strip), description: vat_info.try(:[], 'description'), number: vat_info.try(:[], 'code').try(:strip) },
            is_provider: true,
            account:     provider_account
          }.with_indifferent_access
        end

        if customer_account
          vat_info = vat_codes.select { |e| e['code'].try(:strip).try(:downcase) == account['sales_vat_code'].try(:strip).try(:downcase) }.first
          data << {
            name:        account['name'],
            number:      account['code'].try(:strip).try(:downcase),
            vat:         { code: vat_info.try(:[], 'code').try(:strip), description: vat_info.try(:[], 'description'), number: vat_info.try(:[], 'code').try(:strip) },
            is_provider: false,
            account:     customer_account
          }.with_indifferent_access
        end
        data
      end.flatten
    end

    def send_pre_assignment(data)
      data = JSON.parse(data)

      if data['header']['type'] == 20
        response = pre_assignment_sending :sales_entries, data['payload']
      elsif data['header']['type'] == 22
        response = pre_assignment_sending :purchase_entries, data['payload']
      else
        response = { error: "Journal type #{data['header']['type']} not supported" }
      end

      response
    end

    class RefreshTimeoutError < RuntimeError
    end

  private

    def client
      @exact_online.refresh_session_if_needed
      @client ||= @exact_online.client
    end

    def get_list(*args)
      skip = 0
      result = []
      loop do
        args[-1].merge!({ '$skip' => skip })
        new_result = get *args
        result += new_result
        skip += new_result.size
        break if result.size >= @response_limit
      end
      result
    end

    def get(*args)
      tried_count = 1

      begin
        cl = client
        response = cl.send *args
        @response_limit = cl.result_count
        response
      rescue ExactOnlineLib::Api::Sdk::AuthError
        raise
      rescue Errno::ETIMEDOUT, Timeout::Error
        if tried_count <= 3
          tried_count += 1
          @exact_online.refresh_session_if_needed
          retry
        else
          raise
        end
      end
    end

    def pre_assignment_sending(type, payloads)
      errors    = []

      payloads.each do |payload|
        preseizure = Pack::Report::Preseizure.unscoped.where(id: payload['preseizure_id']).first
        next if preseizure.exact_online_id.present?

        rep     = client.send type.to_sym, payload.except('preseizure_id').to_json.to_s
        tmp_rep = JSON.parse(rep.body)

        if tmp_rep['error'].present?
          message = tmp_rep['error']['message']['value'] || 'erreur inconnu'
          errors << message unless errors.include? message
        else
          preseizure.update(exact_online_id: tmp_rep['d']['EntryNumber'])
        end
        sleep 1 #wait for 1 sec before sending next preseizure
      end

      errors.present? ? { error: errors.join(',') } : { success:  true }
    end
  end
end
