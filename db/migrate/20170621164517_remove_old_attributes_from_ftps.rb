class RemoveOldAttributesFromFtps < ActiveRecord::Migration
  def change
    remove_column :ftps, :old_host,     :string
    remove_column :ftps, :old_login,    :string
    remove_column :ftps, :old_password, :string
  end
end
