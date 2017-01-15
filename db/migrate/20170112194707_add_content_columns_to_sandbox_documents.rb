class AddContentColumnsToSandboxDocuments < ActiveRecord::Migration
  def up
    add_attachment :sandbox_documents, :content
  end

  def down
    remove_attachment :sandbox_documents, :content
  end
end
