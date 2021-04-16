class ArchiveDocumentDuplicated < ActiveRecord::Migration[5.2]
  def change
  	create_table :archive_document_duplicated do |t|
      t.integer	:temp_document_id
      t.integer :temp_pack_id      
      t.string 	:fingerprint      
      
      t.timestamps
    end
  end
end
