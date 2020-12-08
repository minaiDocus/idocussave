class AccountingPlan::IbizaUpdate < AccountingPlan::UpdateService
  def self.execute(user)
    new(user).run
  end

  private

  def execute
    if @user.try(:ibiza).ibiza_id? && @user.uses?(:ibiza) && @accounting_plan.need_update? && get_ibiza_accounting_plan
      @accounting_plan.update(is_updating: true, last_checked_at: Time.now)

      @accounting_plan.providers.update_all(is_updated: false)
      @accounting_plan.customers.update_all(is_updated: false)

      ibiza_accounts.each do |account|
        data = generate_data_for account

        create_item data
      end

      @accounting_plan.is_updating = false
      @accounting_plan.cleanNotUpdatedItems
      @accounting_plan.save
    else
      false
    end
  end

  def ibiza_client
    @ibiza_client ||= @user.organization.ibiza.client
  end

  def get_ibiza_accounting_plan
    ibiza_client.request.clear
    ibiza_client.company(@user.try(:ibiza).try(:ibiza_id)).accounts?

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

  def generate_data_for(account)
    if account.css('category').text.to_i == 1
      kind = 'customer'
    elsif account.css('category').text.to_i == 2
      kind = 'provider'
    end

    { name: account.css('name').text, number: account.css('number').text, associate: account.css('associate').text, kind: kind}
  end
end