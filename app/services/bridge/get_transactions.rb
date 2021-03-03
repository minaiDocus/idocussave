class Bridge::GetTransactions
  def initialize(user)
    @user = user
  end

  def execute
    if @user.bridge_account
      access_token = Bridge::Authenticate.new(@user).execute

      bank_accounts = @user.bank_accounts.configured

      bank_accounts.each do |bank_account|
        if bank_account.operations.any?
          start_time = bank_account.operations.last.created_at.to_time
        else
          start_time = bank_account.created_at.beginning_of_day
        end

        transactions = BridgeBankin::Transaction.list_by_account(account_id: bank_account.api_id, access_token: access_token, since: start_time)

        transactions.each do |transaction|
          if transaction.date >= bank_account.start_date
            @operation = Operation.new(bank_account: bank_account, user: @user, organization: @user.organization)

            save_operation(transaction) unless transaction.is_future || transaction.raw_description == 'Virement'
          end
        end
      end
    end
  end

  private

  def save_operation(transaction)
    @operation.date   = transaction.date
    @operation.amount = transaction.amount
    @operation.label  = @operation.bank_account.type_name == 'card' ? '[CB]' + transaction.raw_description : transaction.raw_description
    @operation.api_id = transaction.id
    @operation.api_name = 'bridge'
    @operation.value_date = transaction.date
    @operation.currency = case transaction.currency_code
                          when 'EUR'
                            @operation.currency = { id: 'EUR', symbol: '€', prefix: false, crypto: false, precision: 2, marketcap: nil, datetime: nil, name: 'Euro'}
                          when 'USD'
                            @operation.currency = { id: 'USD', symbol: '$', prefix: true, crypto: false, precision: 2, marketcap: nil, datetime: nil, name: 'US Dollar'}
                          when 'GBP'
                            @operation.currency = { id: 'GBP', symbol: '£', prefix: false, crypto: false, precision: 2, marketcap: nil, datetime: nil, name: 'British Pound Sterling'}
                          when 'CHF'
                            @operation.currency = { id: 'CHF', symbol: 'CHF', prefix: false, crypto: false, precision: 2, marketcap: nil, datetime: nil, name: 'Swiss Franc'}
                          when 'ZAR'
                            @operation.currency = { id: 'ZAR', symbol: 'R', prefix: false, crypto: false, precision: 2, marketcap: nil, datetime: nil, name: 'South African Rand'}
                          end

    @operation.save
  end
end