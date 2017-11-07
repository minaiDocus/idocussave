class AddContent2ColumnsToRetrievedData < ActiveRecord::Migration
  def up
    add_attachment :retrieved_data, :content2, after: :processed_connection_ids
  end

  def down
    remove_attachment :retrieved_data, :content2
  end
end
