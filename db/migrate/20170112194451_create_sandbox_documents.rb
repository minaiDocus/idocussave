class CreateSandboxDocuments < ActiveRecord::Migration
  def change
    create_table :sandbox_documents do |t|
      t.string :api_id
      t.string :api_name, default: 'budgea'
      t.text :retrieved_metadata

      t.timestamps null: false
    end

    add_reference :sandbox_documents, :user, index: true
    add_reference :sandbox_documents, :retriever, index: true

    add_index :sandbox_documents, :api_id
    add_index :sandbox_documents, :api_name
  end
end
