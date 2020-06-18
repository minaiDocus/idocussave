class AddTokenToTempDocument < ActiveRecord::Migration[5.2]
  def change
    add_column :temp_documents, :token, :string, after: :state, null: true
  end
end
