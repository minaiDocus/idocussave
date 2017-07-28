class AddColumnsToAccountSharings < ActiveRecord::Migration
  def change
    add_reference :account_sharings, :organization, index: true
  end
end
