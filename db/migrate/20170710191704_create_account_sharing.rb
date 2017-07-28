class CreateAccountSharing < ActiveRecord::Migration
  def change
    create_table :account_sharings do |t|
      t.references :collaborator, index: true
      t.references :account, index: true
      t.references :requested_by, index: true
      t.references :authorized_by, index: true
      t.string :role, default: 'editor'

      t.timestamps null: false
    end
  end
end
