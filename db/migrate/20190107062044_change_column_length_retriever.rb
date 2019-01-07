class ChangeColumnLengthRetriever < ActiveRecord::Migration
  def up
    change_column :retrievers, :budgea_error_message, :text, limit: 65535
  end
  def down
    # This might cause trouble if you have strings longer
    # than 255 characters.
    change_column :retrievers, :budgea_error_message, :string
  end
end
