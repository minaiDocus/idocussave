class DestroyBankAccountsWorker
  include Sidekiq::Worker
  sidekiq_options unique: :until_and_while_executing

  def perform(bank_account_ids)
    bank_accounts = BankAccount.find bank_account_ids
    DestroyBankAccounts.new(bank_accounts).execute
  end
end
