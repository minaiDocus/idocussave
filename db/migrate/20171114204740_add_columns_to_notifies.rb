class AddColumnsToNotifies < ActiveRecord::Migration
  def change
    add_column :notifies, :document_being_processed, :boolean, default: true, after: 'r_no_bank_account_configured'
  end
end
