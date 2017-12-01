class UpdatePublishedDocs < ActiveRecord::Migration
  def up
    rename_column :notifies, :published_docs, :published_docs_rm
    add_column :notifies, :published_docs, :string, limit: 5, default: 'now', after: :published_docs_rm
  end

  def down
    remove_column :notifies, :published_docs
    rename_column :notifies, :published_docs_rm, :published_docs
  end
end
