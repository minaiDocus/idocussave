# -*- encoding : UTF-8 -*-
class DestroyBudgeaConnection
  class << self
    def execute(retriever)
      new(retriever).destroy
    end

    def disable_accounts(retriever_id)
      retriever = Retriever.find retriever_id

      if retriever.bank_accounts.any?
        Operation.where(bank_account_id: retriever.bank_accounts.map(&:id)).update_all(api_id: nil) if retriever.uniq?
        # DestroyBankAccountsWorker.perform_in(1.day, retriever.bank_accounts.map(&:id))
      end
      bank_accounts = retriever.bank_accounts || [] #to delete
      retriever.destroy_budgea_connection
      DestroyBankAccounts.new(bank_accounts).execute #to delete
    end
  end

  def initialize(retriever)
    @retriever = retriever
    @user = @retriever.user
  end

  def destroy
    # DestroyBudgeaConnection.delay.disable_accounts(@retriever.id)
    DestroyBudgeaConnection.disable_accounts(@retriever.id) #to delete
    true
  end
end
