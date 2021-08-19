class AddOrganizationToCedricomReception < ActiveRecord::Migration[5.2]
  def change
    add_reference :cedricom_receptions, :organization, index: true, null: true
  end
end
