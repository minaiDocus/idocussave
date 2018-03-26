class CreateMyCompanyFilesSettings < ActiveRecord::Migration
  def change
    create_table :mcf_settings do |t|
      t.references :organization, index: true

      t.string :encrypted_access_token
      t.string :encrypted_refresh_token
      t.string :encrypted_access_token_expires_at
      t.string :delivery_path_pattern, default: '/:year:month/:account_book/'
    end
  end
end
