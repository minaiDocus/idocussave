class Transaction::DestroyBankAccounts
  def initialize(bank_accounts)
    @bank_accounts = bank_accounts
  end

  def execute
    return true
    # @bank_accounts.each do |bank_account|
    #   bank_account.destroy unless bank_account.reload.retriever
    # end
  end
end
