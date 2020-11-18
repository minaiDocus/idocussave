class AccountBookTypeSerializer
  include FastJsonapi::ObjectSerializer
  attributes :id, :user_id, :name, :description, :entry_type, :jefacture_enabled, :charge_account,
             :default_charge_account, :account_number, :default_account_number, :anomaly_account, :vat_account
end