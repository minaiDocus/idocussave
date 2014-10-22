object @user

attributes :code, :company

node :contact do |user|
  user.name
end

node :is_taxable do |user|
  user.options.is_taxable
end

child :compta_processable_journals => :journals do |journal|
  attributes :name, :description, :compta_type, :default_account_number, :account_number, :default_charge_account, :charge_account, :vat_account, :anomaly_account

  child :expense_categories do
    attributes :name, :description
  end
end
