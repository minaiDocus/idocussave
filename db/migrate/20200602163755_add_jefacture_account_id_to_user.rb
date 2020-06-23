class AddJefactureAccountIdToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :jefacture_account_id, :string
  end
end
