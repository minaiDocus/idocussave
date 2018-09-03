class AddSubjectToVatToOrganization < ActiveRecord::Migration
  def change
    add_column :organizations, :subject_to_vat, :boolean, default: true
  end
end
