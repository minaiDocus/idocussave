# -*- encoding : UTF-8 -*-
### Fiduceo related - remained untouched (or nearly) : to be deprecated soon ###
class BankAccountService
  def initialize(user, retriever = nil)
    @user = user
    @retriever = retriever
  end

  def bank_accounts
    results = if @retriever
                client.retriever_bank_accounts(@retriever.fiduceo_id)
              else
                client.bank_accounts
              end
    if client.response.code == 200 && results[1].any?
      results[1].map do |result|
        _bank_account = @user.bank_accounts.where(number: result.account_number).first
        unless _bank_account
          retriever = @retriever || FiduceoRetriever.where(fiduceo_id: result.retriever_id).first
          _bank_account            = BankAccount.new
          _bank_account.user       = @user
          _bank_account.retriever  = retriever
          _bank_account.name       = result.name
          _bank_account.bank_name  = retriever.try(:service_name)
          _bank_account.fiduceo_id = result.id
          _bank_account.number     = result.account_number
        end
        _bank_account
      end
    else
      []
    end
  end

  def find(account_number)
    bank_account = bank_accounts.select do |bank_account|
      bank_account.number == account_number
    end.first
    bank_account
  end

  private

  def client
    @client ||= Fiduceo::Client.new @user.fiduceo_id
  end
end
