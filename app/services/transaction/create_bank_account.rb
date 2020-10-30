# -*- encoding : UTF-8 -*-
class Transaction::CreateBankAccount
  def self.execute(user, bank_list, options={})
    return false unless user.budgea_account.try(:persisted?)

    if bank_list.present?
      banks = bank_list.map{|b| JSON.parse(b.last.to_s.gsub('=>', ':')).to_h.with_indifferent_access}

      banks.group_by{|k, v| k[:id_connection]}.each do |g|
        id_connection = g.first
        bnk = g.last

        retriever = user.retrievers.find_by_budgea_id(id_connection.to_i)

        if retriever
          retriever.bank_accounts.update_all(is_used: false)

          bnk.each do |account|
            bank_account = retriever.bank_accounts.where('api_id = ? OR (name = ? AND number = ?)', account['id'], account['name'], account['number']).first || BankAccount.new
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
        end
      end
    elsif options.try(:[], 'force_disable') && options.try(:[], 'force_disable') == 'true'
      user.bank_accounts.update_all(is_used: false)
    end
    true
  end
end
