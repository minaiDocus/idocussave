class ChangeColumnsOfIbizas < ActiveRecord::Migration
  def change
    change_table :ibizas, bulk: true do |t|
      t.rename :access_token, :old_access_token
      t.column :encrypted_access_token, :text

      t.rename :access_token_2, :old_access_token_2
      t.column :encrypted_access_token_2, :text
    end
  end
end
