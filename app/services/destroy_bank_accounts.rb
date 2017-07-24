class DestroyBankAccounts
  def initialize(bank_accounts)
    @bank_accounts = bank_accounts
  end

  def execute
    @bank_accounts.each do |bank_account|
      bank_account.destroy unless bank_account.retriever
    end
  end
end
