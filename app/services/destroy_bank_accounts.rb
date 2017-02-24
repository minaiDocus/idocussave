class DestroyBankAccounts
  def initialize(bank_accounts)
    @bank_accounts = bank_accounts
  end

  def execute
    @bank_accounts.each do |bank_account|
      unless bank_account.retriever
        bank_account.operations.update_all(api_id: nil)
        bank_account.destroy
      end
    end
  end
end
