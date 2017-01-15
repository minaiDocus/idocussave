class CreateSandboxOperations < ActiveRecord::Migration
  def change
    create_table :sandbox_operations do |t|
      t.string :api_id
      t.string :api_name, default: 'budgea'
      t.date :date
      t.date :value_date
      t.date :transaction_date
      t.string :label
      t.decimal :amount
      t.string :comment
      t.string :supplier_found
      t.string :type_name
      t.integer :category_id
      t.string :category
      t.boolean :is_locked

      t.timestamps null: false
    end

    add_reference :sandbox_operations, :organization, index: true
    add_reference :sandbox_operations, :user
    add_reference :sandbox_operations, :sandbox_bank_account

    add_index :sandbox_operations, :api_id
    add_index :sandbox_operations, :api_name
  end
end
