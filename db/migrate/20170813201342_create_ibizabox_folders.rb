class CreateIbizaboxFolders < ActiveRecord::Migration
  def change
    create_table :ibizabox_folders do |t|
      t.references :journal
      t.references :user
      t.boolean :is_selection_needed, default: true
      t.string :state
      t.datetime :last_checked_at
      t.string :error_message

      t.timestamps null: false
    end
  end
end
