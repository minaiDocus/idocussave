class AddVatIdentifierToOrganization < ActiveRecord::Migration[5.2]
  def change
    add_column :organizations, :vat_identifier, :string
  end
end
