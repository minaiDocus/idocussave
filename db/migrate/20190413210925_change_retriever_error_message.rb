class ChangeRetrieverErrorMessage < ActiveRecord::Migration[5.2]
  def change
    change_column :retrievers, :error_message, :text
  end
end
