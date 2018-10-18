# -*- encoding : UTF-8 -*-
class ExactOnlineData
  def initialize(object, division=nil)
    if object.class.in?([String, BSON::ObjectId])
      @exact_online = ExactOnline.find exact_online_id
    else
      @exact_online = object
    end
    @division = division
  end

  def accounts
    @accounts ||= Rails.cache.fetch ['exact_online', @division, 'accounts'], expires_in: 10.hours do
      get_list :accounts, @division, '$inlinecount' => 'allpages', '$orderby' => 'Code'
    end
  end

  def gl_accounts
    @gl_accounts ||= Rails.cache.fetch ['exact_online', @division, 'gl_accounts'], expires_in: 10.hours do
      get_list :gl_accounts, @division, '$inlinecount' => 'allpages', '$orderby' => 'Code'
    end
  end

  def journals
    @journals ||= Rails.cache.fetch ['exact_online', @division, 'journals'], expires_in: 10.hours do
      get_list :journals, @division, {
        '$inlinecount' => 'allpages',
        '$orderby'     => 'Code',
        '$select'      => 'Code,Description,Type'
      }
    end
  end

  def accounting_plans
    @accounting_plans ||= accounts.map do |account|
      provider_account = gl_accounts.select { |e| e['id'] == account['gl_account_purchase'] }.first.try(:[], 'code')
      customer_account = gl_accounts.select { |e| e['id'] == account['gl_account_sales'] }.first.try(:[], 'code')

      data = []
      if provider_account
        data << {
          name:        account['name'],
          is_provider: true,
          account:     provider_account
        }.with_indifferent_access
      end
      if customer_account
        data << {
          name:        account['name'],
          is_provider: false,
          account:     customer_account
        }.with_indifferent_access
      end
      data
    end.flatten
  end

  def journal_entries
    get_list :journal_entries
  end

  class RefreshTimeoutError < RuntimeError
  end

private

  def client
    @exact_online.client(@division)
  end

  def get_list(*args)
    skip = 0
    result = []
    loop do
      args[-1].merge!({ '$skip' => skip })
      new_result = get *args
      result += new_result
      skip += new_result.size
      break if result.size >= client.result_count
    end
    result
  end

  def get(*args)
    tried_count = 1
    @exact_online.refresh_session_if_needed
    begin
      client.send *args
    rescue ExactOnlineSdk::AuthError
      if @exact_online.is_session_expired? && tried_count <= 3
        tried_count += 1
        @exact_online.refresh_session
        retry
      else
        raise
      end
    rescue Errno::ETIMEDOUT, Timeout::Error
      if tried_count <= 3
        tried_count += 1
        retry
      else
        raise
      end
    end
  end
end
