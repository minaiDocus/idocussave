# -*- encoding : UTf-8 -*-
class UpdateAccountingPlan
  # Come accross all organizations customers to update their accounting plan
  def self.execute
    Organization.all.each do |organization|
      next unless organization.ibiza.try(:configured?) || organization.is_exact_online_used
      organization.customers.order(code: :asc).active.each do |customer|
        new(customer).execute
        print '.'
      end
    end
  end


  def initialize(user)
    @user = user
    @accounting_plan = user.accounting_plan
  end

  def execute
    if @user.ibiza_id.present? && @user.uses_ibiza? && @accounting_plan.need_update? && @user.softwares.ibiza_auto_update_accounting_plan?
      if get_ibiza_accounting_plan
        @accounting_plan.update(is_updating: true, last_checked_at: Time.now)

        @accounting_plan.providers.update_all(is_updated: false)
        @accounting_plan.customers.update_all(is_updated: false)

        ibiza_accounts.each do |account|
          create_ibiza_item(account)
        end

        @accounting_plan.is_updating = false
        @accounting_plan.cleanNotUpdatedItems
        @accounting_plan.save
      else
        false
      end
    elsif @user.exact_online.try(:fully_configured?) && @user.uses_exact_online? && @accounting_plan.need_update?
      if exact_online_accounts.present?
        @accounting_plan.update(is_updating: true, last_checked_at: Time.now)

        @accounting_plan.providers.update_all(is_updated: false)
        @accounting_plan.customers.update_all(is_updated: false)
        @accounting_plan.vat_accounts = [] #TODO : exact online will be removed so we don't change vat_accounts process

        exact_online_accounts.each do |account|
          create_exact_online_item(account)
        end

        @accounting_plan.is_updating = false
        @accounting_plan.cleanNotUpdatedItems
        @accounting_plan.save
      else
        false
      end
    else
      false
    end
  end

  def ibiza_error_message
    ibiza_client.response.message unless ibiza_client.response.success?
  end

  private


  def ibiza_client
    @ibiza_client ||= @user.organization.ibiza.client
  end


  def get_ibiza_accounting_plan
    ibiza_client.request.clear
    ibiza_client.company(@user.ibiza_id).accounts?

    if ibiza_client.response.success?
      @xml_data = ibiza_client.response.body.force_encoding('UTF-8')
    else
      false
    end
  end

  def ibiza_accounts
    Nokogiri::XML(@xml_data).css('wsAccounts').select do |account|
      account.css('closed').text.to_i == 0 && account.css('category').text.to_i.in?([1, 2])
    end
  end


  def create_ibiza_item(account)
    item = AccountingPlanItem.find_by_name_and_account(@accounting_plan.id, account.css('name').text, account.css('number').text) || AccountingPlanItem.new
    item.third_party_name    = account.css('name').text
    item.third_party_account = account.css('number').text
    item.conterpart_account  = account.css('associate').text
    item.is_updated          = true

    if account.css('category').text.to_i == 1
      item.kind = 'customer'
    elsif account.css('category').text.to_i == 2
      item.kind = 'provider'
    end

    @accounting_plan.customers << item if item.kind == 'customer'
    @accounting_plan.providers << item if item.kind == 'provider'
  end

  def create_exact_online_item(account)
    item = AccountingPlanItem.find_by_name_and_account(@accounting_plan.id, account[:name], account[:number]) || AccountingPlanItem.new
    item.third_party_name       = account[:name]
    item.third_party_account    = account[:number]
    item.conterpart_account     = account[:account]
    item.code                   = account[:vat][:code] if account[:vat][:code].present?
    item.kind                   = account[:is_provider] ? 'provider' : 'customer'
    item.is_updated             = true

    @accounting_plan.customers << item if item.kind == 'customer'
    @accounting_plan.providers << item if item.kind == 'provider'
    @accounting_plan.vat_accounts << create_exact_online_vat_account(account[:vat]) if account[:vat][:code].present?
  end

  def create_exact_online_vat_account(vat_infos)
    vat                = AccountingPlanVatAccount.new
    vat.code           = vat_infos[:code]
    vat.nature         = vat_infos[:description]
    vat.account_number = vat_infos[:number]
    vat.save

    vat
  end

  def exact_online_accounts
    @exact_online_accounts ||= ExactOnlineData.new(@user).accounting_plans
  end
end


