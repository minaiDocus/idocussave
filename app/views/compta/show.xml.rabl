object @user

attributes :code, :company

node :contact do |user|
  user.name
end

child :compta_processable_journals => :journals do |journal|
  attributes :name, :description, :compta_type, :account_number, :charge_account
end