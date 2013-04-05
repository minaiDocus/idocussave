object @user

attributes :code, :company

node :contact do |user|
  user.name
end

child :compta_processable_journals => :journals do |journal|
  attributes :name, :description, :compta_type, :default_account_number, :account_number, :default_charge_account, :charge_account, :vat_account, :anomaly_account
end