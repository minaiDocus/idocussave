class CreateSandboxBankAccounts < ActiveRecord::Migration
  def change
    create_table :sandbox_bank_accounts do |t|
      t.string :api_id
      t.string :api_name, default: 'budgea'
      t.string :bank_name
      t.string :name
      t.string :number
      t.boolean :is_used, default: false
      t.string :journal
      t.string :foreign_journal
      t.string :accounting_number, default: '512000'
      t.string :temporary_account, default: '471000'
      t.date :start_date

      t.timestamps null: false
    end

    add_reference :sandbox_bank_accounts, :user, index: true
    add_reference :sandbox_bank_accounts, :retriever, index: true
  end
end
