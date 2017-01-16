class ChangeColumnContentFromRetrievedData < ActiveRecord::Migration
  def up
    change_column :retrieved_data, :content, :text, limit: 16777215
  end

  def down
    change_column :retrieved_data, :content, :text, limit: 65535
  end
end
