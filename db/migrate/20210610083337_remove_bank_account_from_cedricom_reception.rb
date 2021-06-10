class RemoveBankAccountFromCedricomReception < ActiveRecord::Migration[5.2]
  def change
    remove_column :cedricom_receptions, :bank_account_id
  end
end
