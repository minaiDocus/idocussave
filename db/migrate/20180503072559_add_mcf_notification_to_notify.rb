class AddMcfNotificationToNotify < ActiveRecord::Migration
  def change
    add_column :notifies, :mcf_document_errors, :boolean, default: false
  end
end
