class AddUserIndexToSoftwaresSettings < ActiveRecord::Migration
  def change
    add_index :softwares_settings, :user_id
  end
end
