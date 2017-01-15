class AddContentFingerprintColumnToSandboxDocuments < ActiveRecord::Migration
  def up
    add_column :sandbox_documents, :content_fingerprint, :string
  end

  def down
    remove_column :sandbox_documents, :content_fingerprint
  end
end
