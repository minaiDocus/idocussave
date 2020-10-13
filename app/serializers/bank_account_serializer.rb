class BankAccountSerializer
  include FastJsonapi::ObjectSerializer
  attributes :id, :user_id, :name, :number, :currency
end