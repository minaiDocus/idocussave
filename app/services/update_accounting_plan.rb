# -*- encoding : UTf-8 -*-
class UpdateAccountingPlan
  # Come accross all organizations customers to update their accounting plan
  def self.execute
    Organization.all.each do |organization|
      next unless organization.ibiza.try(:configured?)
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
    if @user.ibiza_id.present? && @user.organization.try(:ibiza).try(:configured?)
      if get_ibiza_accounting_plan
        @accounting_plan.providers = []
        @accounting_plan.customers = []

        accounts.each do |account|
          create_item(account)
        end

        @accounting_plan.save
      else
        false
      end
    else
      false
    end
  end


  def error_message
    client.response.message unless client.response.success?
  end

  private


  def client
    @client ||= @user.organization.ibiza.client
  end


  def get_ibiza_accounting_plan
    client.request.clear
    client.company(@user.ibiza_id).accounts?

    @accounting_plan.update(last_checked_at: Time.now)

    if client.response.success?
      @xml_data = client.response.body.force_encoding('UTF-8')
    else
      false
    end
  end


  def accounts
    Nokogiri::XML(@xml_data).css('wsAccounts').select do |account|
      account.css('closed').text.to_i == 0 && account.css('category').text.to_i.in?([1, 2])
    end
  end


  def create_item(account)
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
end


