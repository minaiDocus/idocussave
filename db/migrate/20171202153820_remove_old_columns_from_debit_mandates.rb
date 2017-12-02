class RemoveOldColumnsFromDebitMandates < ActiveRecord::Migration
  def change
    remove_column :debit_mandates, :mongo_id, :string
    remove_column :debit_mandates, :user_id_mongo_id, :string
    remove_column :debit_mandates, :user_id, :integer
  end
end
