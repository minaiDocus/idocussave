class CreateBudgeaAccount < ActiveRecord::Migration
  def change
    create_table :budgea_accounts do |t|
      t.string :identifier
      t.string :access_token

      t.timestamps null: false
    end

    add_reference :budgea_accounts, :user, foreign_key: true
  end
end
