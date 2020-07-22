class IncreaseErrorMessageLength < ActiveRecord::Migration[5.2]
  def change
  	change_column :archive_retrievers, :error_message, :text
  	change_column :archive_retrievers, :error, :text

  	add_index :archive_retrievers, :is_updated
    add_index :archive_retrievers, :exist
    add_index :archive_retrievers, :state
    add_index :archive_retrievers, :active

    add_index :archive_budgea_users, :is_updated
    add_index :archive_budgea_users, :exist
  end
end
