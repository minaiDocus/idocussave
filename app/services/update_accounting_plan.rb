# -*- encoding : UTf-8 -*-
class UpdateAccountingPlan
  # Come accross all organizations customers to update their accounting plan
  def self.execute
    Organization.all.each do |organization|
      next unless organization.ibiza.try(:configured?) || organization.exact_online.try(:configured?)
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
    if @user.ibiza_id.present? && @user.uses_ibiza? && @user.organization.try(:ibiza).try(:configured?) && @accounting_plan.need_update?
      if get_ibiza_accounting_plan
        @accounting_plan.update(is_updating: true, last_checked_at: Time.now)

        @accounting_plan.providers = []
        @accounting_plan.customers = []

        ibiza_accounts.each do |account|
          create_ibiza_item(account)
        end

        @accounting_plan.is_updating = false
        @accounting_plan.save
      else
        false
      end
    elsif @user.exact_id.present? && @user.organization.exact_online.try(:configured?) && @accounting_plan.need_update?
      if exact_accounts.present?
        @accounting_plan.update(is_updating: true, last_checked_at: Time.now)

        @accounting_plan.providers = []
        @accounting_plan.customers = []

        exact_accounts.each do |account|
          create_exact_item(account)
        end

        @accounting_plan.is_updating = false
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
    @ibiza_client ||= @user.organization.ibiza.ibiza_client
  end


  def get_ibiza_accounting_plan
    ibiza_client.request.clear
    ibiza_client.company(@user.ibiza_id).accounts?

    if client.response.success?
      @xml_data = client.response.body.force_encoding('UTF-8')
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
    item = AccountingPlanItem.new
    item.third_party_name    = account.css('name').text
    item.third_party_account = account.css('number').text
    item.conterpart_account  = account.css('associate').text

    if account.css('category').text.to_i == 1
      item.kind = 'customer'
    elsif account.css('category').text.to_i == 2
      item.kind = 'provider'
    end

    @accounting_plan.customers << item if item.kind == 'customer'
    @accounting_plan.providers << item if item.kind == 'provider'
  end

  def create_exact_item(account)
    item = AccountingPlanItem.new
    item.third_party_name       = account[:name]
    item.conterpart_account     = account[:account]
    item.no_third_party_account = true

    if account[:is_provider]
      @accounting_plan.providers << item
    else
      @accounting_plan.customers << item
    end
  end

  def exact_data
    @exact_data ||= ExactOnlineData.new(@user.organization.exact_online, @user.exact_id)
  end

  def exact_accounts
    @exact_accounts ||= exact_data.accounting_plans
  end
end


