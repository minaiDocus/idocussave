class OperationSerializer
  include FastJsonapi::ObjectSerializer
  attributes :id, :user_id, :organization_id, :bank_account_id, :currency, :date, :value_date, :amount, :label
end