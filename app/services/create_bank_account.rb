# -*- encoding : UTF-8 -*-
class CreateBankAccount
  def self.execute(user, connector_id, bank_list)
    return false unless user.budgea_account.try(:persisted?)
    retriever = user.retrievers.find_by_budgea_id(connector_id)

    retriever.bank_accounts.update_all(is_used: false)

    bank_list.each do |index, account|
      bank_account = retriever.bank_accounts.where(api_id: account['id'], number: account['number'], name: account['name']).first || BankAccount.new
      bank_account.user              = user
      bank_account.retriever         = retriever
      bank_account.api_id            = account['id']
      bank_account.bank_name         = retriever.service_name
      bank_account.name              = account['name']
      bank_account.number            = account['number']
      bank_account.type_name         = account['type']
      bank_account.original_currency = account['currency']
      bank_account.is_used           = true
      bank_account.save
    end
    true
  end
end
