class ChangeMyUnisoftsToSoftwareMyUnisofts < ActiveRecord::Migration[5.2]
  def change
    rename_table :my_unisofts, :software_my_unisofts
    rename_column :software_my_unisofts, :auto_update_accounting_plan, :is_auto_updating_accounting_plan
    change_column_default :software_my_unisofts, :is_auto_updating_accounting_plan, from: false, to: true
  end
end
