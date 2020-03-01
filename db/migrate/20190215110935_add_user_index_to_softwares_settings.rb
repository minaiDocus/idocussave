class AddUserIndexToSoftwaresSettings < ActiveRecord::Migration[5.2]
  def change
    add_index :softwares_settings, :user_id
  end
end
