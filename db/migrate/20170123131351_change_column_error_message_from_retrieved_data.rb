class ChangeColumnErrorMessageFromRetrievedData < ActiveRecord::Migration
    def up
    change_column :retrieved_data, :error_message, :text, limit: 16777215
  end

  def down
    change_column :retrieved_data, :error_message, :string
  end
end
