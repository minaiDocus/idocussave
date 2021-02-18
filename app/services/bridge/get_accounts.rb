class Bridge::GetAccounts
  def initialize(user)
    @user = user
  end

  def execute
    if @user.bridge_account
      access_token = Bridge::Authenticate.new(@user).execute

      accounts = BridgeBankin::Account.list(access_token: access_token)

      accounts.each do |account|
        retriever = Retriever.find_by_bridge_id(account.item.id)

        bank_account = BankAccount.find_or_initialize_by(user: retriever.user, api_name: 'bridge', api_id: account.id, retriever: retriever)


        bank_account.update(name: account.name,
                            number: account.iban,
                            is_used: true,
                            currency: account.currency_code,
                            type_name: account.type,
                            bank_name: retriever.name)
      end
    end
  end
end