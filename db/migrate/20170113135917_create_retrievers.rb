class CreateRetrievers < ActiveRecord::Migration
  def change
    create_table :retrievers do |t|
      t.integer :budgea_id
      t.string :fiduceo_id
      t.string :fiduceo_transaction_id
      t.string :name
      t.text :param1
      t.text :param2
      t.text :param3
      t.text :param4
      t.text :param5
      t.text :additionnal_fields
      t.text :answers
      t.string :journal_name
      t.datetime :sync_at
      t.boolean :is_sane, default: true
      t.boolean :is_new_password_needed, default: false
      t.boolean :is_selection_needed, default: true
      t.string :state
      t.string :error_message
      t.string :budgea_state
      t.text :budgea_additionnal_fields
      t.string :budgea_error_message
      t.string :fiduceo_state
      t.text :fiduceo_additionnal_fields
      t.string :fiduceo_error_message

      t.timestamps null: false
    end

    add_reference :retrievers, :user, foreign_key: true
    add_reference :retrievers, :journal, foreign_key: true
    add_reference :retrievers, :connector, foreign_key: true

    add_index :retrievers, :state
  end
end
