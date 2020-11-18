class AccountingPlanItemSerializer
  include FastJsonapi::ObjectSerializer
  attributes :id, :third_party_name, :third_party_account, :conterpart_account, :vat_autoliquidation, :code,
             :vat_autoliquidation_credit_account, :vat_autoliquidation_debit_account
end