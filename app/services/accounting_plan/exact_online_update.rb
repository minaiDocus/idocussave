class AccountingPlan::ExactOnlineUpdate < AccountingPlan::UpdateService
  def self.execute(user)
    new(user).run
  end

  private

  def execute
    if @user.exact_online.try(:fully_configured?) && @user.uses?(:exact_online) && @accounting_plan.need_update? && exact_online_accounts.present?

        @accounting_plan.update(is_updating: true, last_checked_at: Time.now)

        @accounting_plan.providers.update_all(is_updated: false)
        @accounting_plan.customers.update_all(is_updated: false)
        @accounting_plan.vat_accounts = [] #TODO : exact online will be removed so we don't change vat_accounts process

        exact_online_accounts.each do |account|
          data = generate_data_for account

          create_item data

          @accounting_plan.vat_accounts << create_exact_online_vat_account(account[:vat]) if account[:vat][:code].present?
        end

        @accounting_plan.is_updating = false
        @accounting_plan.cleanNotUpdatedItems
        @accounting_plan.save
    else
      false
    end
  end

  def generate_data_for(account)
    kind = account[:is_provider] ? 'provider' : 'customer'
    code = account[:vat][:code].presence || nil

    { name: account[:name], number: account[:number], associate: account[:account], kind: kind, code: code}
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
    @exact_online_accounts ||= ExactOnlineLib::Data.new(@user).accounting_plans
  end
end