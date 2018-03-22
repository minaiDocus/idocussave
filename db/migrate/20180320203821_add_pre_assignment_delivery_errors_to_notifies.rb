class AddPreAssignmentDeliveryErrorsToNotifies < ActiveRecord::Migration
  def change
    add_column :notifies, :pre_assignment_delivery_errors, :string, default: 'none', after: :new_scanned_documents
  end
end
