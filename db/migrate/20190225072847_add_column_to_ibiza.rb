class AddColumnToIbiza < ActiveRecord::Migration[5.2]
  def change
    add_column :ibizas, :voucher_ref_target, :string, default: 'piece_number', after: :piece_name_format_sep
  end
end
