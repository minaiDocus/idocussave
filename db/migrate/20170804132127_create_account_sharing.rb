class CreateAccountSharing < ActiveRecord::Migration
  def change
    create_table :account_sharings do |t|
      t.references :organization, index: true
      t.references :collaborator, index: true
      t.references :account, index: true
      t.references :authorized_by, index: true

      t.column :is_approved, :boolean, default: false
      t.index :is_approved

      t.timestamps null: false
    end
  end
end
