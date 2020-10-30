# -*- encoding : UTF-8 -*-
class Retriever::DestroyBudgeaConnection
  class << self
    def execute(retriever)
      new(retriever).destroy
    end

    def disable_accounts(retriever_id)
      retriever = Retriever.find retriever_id

      if retriever.bank_accounts.any?
        Operation.where(bank_account_id: retriever.bank_accounts.map(&:id)).update_all(api_id: nil) if retriever.uniq?
        Transaction::DestroyBankAccountsWorker.perform_in(1.day, retriever.bank_accounts.map(&:id))
      end
      retriever.destroy_budgea_connection
    end
  end

  def initialize(retriever)
    @retriever = retriever
    @user = @retriever.user
  end

  def destroy
    Retriever::DestroyBudgeaConnection.delay.disable_accounts(@retriever.id)
    true
  end
end
