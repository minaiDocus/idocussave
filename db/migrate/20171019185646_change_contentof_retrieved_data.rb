class ChangeContentofRetrievedData < ActiveRecord::Migration
  def up
    change_column :retrieved_data, :content, :text, limit: 4294967295
  end

  def down
    change_column :retrieved_data, :content, :text, limit: 16777215
  end
end
