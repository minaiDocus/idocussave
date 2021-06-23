class SetFecAcdAutoDeliverDefault < ActiveRecord::Migration[5.2]
  def change
    change_column :software_fec_acds, :auto_deliver, :integer, default: -1
  end
end
