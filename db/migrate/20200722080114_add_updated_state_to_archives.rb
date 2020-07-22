class AddUpdatedStateToArchives < ActiveRecord::Migration[5.2]
  def change
  	add_column :archive_budgea_users, :is_updated, :boolean, default: false
  	add_column :archive_retrievers, :is_updated, :boolean, default: false
  end
end
