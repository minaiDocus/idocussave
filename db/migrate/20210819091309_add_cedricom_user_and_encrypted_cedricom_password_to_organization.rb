class AddCedricomUserAndEncryptedCedricomPasswordToOrganization < ActiveRecord::Migration[5.2]
  def change
    add_column :organizations, :cedricom_user, :string
    add_column :organizations, :encrypted_cedricom_password, :string
  end
end
