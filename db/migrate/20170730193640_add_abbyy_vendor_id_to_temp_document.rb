class AddAbbyyVendorIdToTempDocument < ActiveRecord::Migration
  def change
    add_column :temp_documents, :abbyy_vendor_id, :integer
  end
end
