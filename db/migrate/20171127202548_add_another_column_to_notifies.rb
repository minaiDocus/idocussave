class AddAnotherColumnToNotifies < ActiveRecord::Migration
  def change
    add_column :notifies, :r_wrong_pass, :boolean, default: true, after: :reception_of_emailed_docs
  end
end
