class AddOriginalFingerprintToTempDocument < ActiveRecord::Migration
  def change
    add_column :temp_documents, :original_fingerprint, :string, limit: 255, after: :content_fingerprint
  end
end
