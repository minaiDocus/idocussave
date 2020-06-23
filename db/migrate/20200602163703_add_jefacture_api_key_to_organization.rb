class AddJefactureApiKeyToOrganization < ActiveRecord::Migration[5.2]
  def change
    add_column :organizations, :jefacture_api_key, :string
  end
end
