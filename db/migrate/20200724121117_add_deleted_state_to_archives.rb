class AddDeletedStateToArchives < ActiveRecord::Migration[5.2]
  def change
  	add_column :archive_budgea_users, :is_deleted, :boolean, default: false
  	add_column :archive_budgea_users, :deleted_date, :datetime
  	add_column :archive_retrievers, :is_deleted, :boolean, default: false
  	add_column :archive_retrievers, :deleted_date, :datetime
  end
end
