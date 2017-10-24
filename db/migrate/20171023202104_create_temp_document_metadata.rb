class CreateTempDocumentMetadata < ActiveRecord::Migration
  def up
    create_table :temp_document_metadata do |t|
      t.datetime :date
      t.string :name, limit: 191
      t.decimal :amount, precision: 10, scale: 2
      t.timestamps null: false

      t.references :temp_document, index: true
    end

    execute "ALTER TABLE temp_document_metadata CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_bin"
  end

  def down
    drop_table :temp_document_metadata
  end
end
