class AddIsIbizaAutoUpdatingAccountingPlanToSoftwaresSetting < ActiveRecord::Migration[5.2]
  def change
    add_column :softwares_settings, :is_ibiza_auto_updating_accounting_plan, :integer, after: :is_ibiza_auto_deliver, default: 1
  end
end
