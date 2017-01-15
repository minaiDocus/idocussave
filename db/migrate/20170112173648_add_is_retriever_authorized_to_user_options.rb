class AddIsRetrieverAuthorizedToUserOptions < ActiveRecord::Migration
  def change
    add_column :user_options, :is_retriever_authorized, :boolean, default: false
  end
end
