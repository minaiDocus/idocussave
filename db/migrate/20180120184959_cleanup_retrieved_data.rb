class CleanupRetrievedData < ActiveRecord::Migration
  def change
    change_table :retrieved_data, bulk: true do |t|
      t.remove :content
      t.rename :content2_file_name,    :content_file_name
      t.rename :content2_file_size,    :content_file_size
      t.rename :content2_updated_at,   :content_updated_at
      t.rename :content2_content_type, :content_content_type
    end
  end
end
