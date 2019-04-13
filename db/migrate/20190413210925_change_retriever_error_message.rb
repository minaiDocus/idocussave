class ChangeRetrieverErrorMessage < ActiveRecord::Migration
  def change
    change_column :retrievers, :error_message, :text
  end
end
