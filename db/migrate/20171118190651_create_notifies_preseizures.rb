class CreateNotifiesPreseizures < ActiveRecord::Migration
  def change
    create_table :notifies_preseizures do |t|
      t.belongs_to :notify
      t.belongs_to :preseizure

      t.index [:notify_id, :preseizure_id], name: 'index_notify_id_preseizure_id'
    end
  end
end
