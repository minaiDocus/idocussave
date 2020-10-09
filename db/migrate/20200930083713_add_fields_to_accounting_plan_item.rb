class AddFieldsToAccountingPlanItem < ActiveRecord::Migration[5.2]
  def change
    add_column :accounting_plan_items, :vat_autoliquidation, :boolean
    add_column :accounting_plan_items, :vat_autoliquidation_credit_account, :string
    add_column :accounting_plan_items, :vat_autoliquidation_debit_account, :string
  end
end
