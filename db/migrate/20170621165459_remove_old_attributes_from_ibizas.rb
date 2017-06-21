class RemoveOldAttributesFromIbizas < ActiveRecord::Migration
  def change
    remove_column :ibizas, :old_access_token,   :string
    remove_column :ibizas, :old_access_token_2, :string
  end
end
