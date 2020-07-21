class AddBudgeaUserArchives < ActiveRecord::Migration[5.2]
  def change
    create_table :archive_budgea_users do |t|
      t.integer :identifier
      t.date    :signin
      t.string  :platform
      t.text    :encrypted_access_token
      t.boolean :exist
    end
  end
end
