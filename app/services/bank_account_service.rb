# -*- encoding : UTF-8 -*-
class BankAccountService
  def initialize(user)
    @user = user
  end

  def bank_accounts
    results = client.bank_accounts
    if client.response.code == 200 && results[1].any?
      results[1].map do |result|
        retriever = FiduceoRetriever.where(fiduceo_id: result.retriever_id).first
        _bank_account = @user.bank_accounts.where(number: result.account_number).first
        unless _bank_account
          _bank_account = BankAccount.new(user_id: @user.id)
          _bank_account.bank_name = retriever.service_name
          _bank_account.fiduceo_id = result.id
          _bank_account.number = result.account_number
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
    raise Mongoid::Errors::DocumentNotFound.new(::BankAccount, account_number) unless bank_account
    bank_account
  end

private

  def client
    @client ||= Fiduceo::Client.new @user.fiduceo_id
  end
end
