object @user

attributes :code, :company

node :contact do |user|
  user.name
end

node :is_taxable do |user|
  user.options.is_taxable if user.options
end

child :compta_processable_journals => :journals do |journal|
  attributes :name, :description, :compta_type, :default_account_number, :account_number, :default_charge_account, :charge_account, :vat_accounts, :vat_account, :vat_account_10, :vat_account_8_5, :vat_account_5_5, :vat_account_2_1, :anomaly_account, :currency

  child :expense_categories do
    attributes :name, :description
  end
end
