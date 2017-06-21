class RemoveOldAttributesFromKnowings < ActiveRecord::Migration
  def change
    remove_column :knowings, :old_username, :string
    remove_column :knowings, :old_password, :string
    remove_column :knowings, :old_url,      :string
  end
end
