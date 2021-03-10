class AddSpecificUrlOptionsToIbiza < ActiveRecord::Migration[5.2]
  def change
    add_column :ibizas, :specific_url_options, :string, after: :voucher_ref_target
  end
end
