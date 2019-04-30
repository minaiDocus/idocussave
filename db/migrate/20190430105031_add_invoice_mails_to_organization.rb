class AddInvoiceMailsToOrganization < ActiveRecord::Migration
  def change
    add_column :organizations, :invoice_mails, :string
  end
end
