class ArchiveAlreadyExist < ActiveRecord::Migration[5.2]
  def change
	create_table :archive_already_exist do |t|
      t.integer	:temp_document_id
      t.text :path
      t.text :token
      t.string :fingerprint
      t.string :original_file_name

      t.timestamps
    end
  end
end
