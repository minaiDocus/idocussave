class ChangeColumnContentFromRetrievedData < ActiveRecord::Migration
  def change
    change_column :retrieved_data, :content, :text, limit: 16777215
  end
end
