class AddPreseizureDateOptionToOptions < ActiveRecord::Migration
  def change
    add_column :organizations, :preseizure_date_option, :integer, default: 0, after: :is_operation_value_date_needed
    add_column :user_options, :preseizure_date_option, :integer, default: -1, after: :is_operation_value_date_needed
  end
end
