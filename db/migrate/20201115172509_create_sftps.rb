class CreateSftps < ActiveRecord::Migration[5.2]
  def change
    create_table :sftps do |t|
      t.string :path, default: "iDocus/:code/:year:month/:account_book/", null: false
      t.boolean :is_configured, default: false, null: false
      t.datetime :error_fetched_at
      t.text :error_message, limit: 4294967295
      t.references :external_file_storage
      t.string :encrypted_host
      t.string :encrypted_login
      t.string :encrypted_password
      t.string :encrypted_port
      t.string :root_path, default: "/"
      t.datetime :import_checked_at
      t.string :previous_import_paths
      t.references :organization

      t.timestamps
    end
  end
end
