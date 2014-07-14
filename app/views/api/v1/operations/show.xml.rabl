object @operation

attributes :id, :date, :label, :amount

node :journal do |operation|
  operation.bank_account.try(:journal)
end

node :bank_name do |operation|
  operation.bank_account.try(:bank_name)
end

node :account_number do |operation|
  operation.bank_account.try(:number)
end

node :credit do |operation|
  if operation.amount >= 0
    operation.amount
  end
end

node :debit do |operation|
  if operation.amount < 0
    operation.amount
  end
end
