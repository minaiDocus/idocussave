class AccountingPlan::MyUnisoftUpdate < AccountingPlan::UpdateService
  def self.execute(user)
    new(user).run
  end

  private

  def execute    
    if @user.try(:my_unisoft).try(:present?) && @user.my_unisoft.user_used && @accounting_plan.need_update?
      @accounting_plan.update(is_updating: true, last_checked_at: Time.now)

      @accounting_plan.providers.update_all(is_updated: false)
      @accounting_plan.customers.update_all(is_updated: false)

      my_unisoft_accounts['account_array'].each do |account|
        data = generate_data_for account

        create_item data if data.present?
      end

      @accounting_plan.is_updating = false
      @accounting_plan.cleanNotUpdatedItems
      @accounting_plan.save
    else
      false
    end
  end

  def my_unisoft_client
    @my_unisoft_client ||= MyUnisoft::Client.new(@user.my_unisoft.api_token)
  end

  def my_unisoft_accounts
    accounts = my_unisoft_client.get_account(@user.my_unisoft.society_id)

    accounts[:status] == "success" ? accounts[:body] : []
  end

  def generate_data_for(account)
    if %w(411).include?(account['account_number'].to_s[0..2]) && account['account_number'] != "411000"
      kind = 'customer'
    elsif %w(401).include?(account['account_number'].to_s[0..2]) && account['account_number'] != "401000"
      kind = 'provider'
    end

    associate = account['counterpart_account'].nil? ?  "" : account['counterpart_account']['account_number']

    { name: account['label'], number: account['account_number'], associate: associate, kind: kind } if %w(401 411).include?(account['account_number'].to_s[0..2]) && kind.present?
  end
end