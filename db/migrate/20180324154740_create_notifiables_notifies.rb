class CreateNotifiablesNotifies < ActiveRecord::Migration
  def change
    create_table :notifiables_notifies do |t|
      t.belongs_to :notifiable, polymorphic: true
      t.belongs_to :notify

      t.column :label, :string

      t.index [:notify_id, :notifiable_id, :notifiable_type, :label], name: 'index_notifiable'
    end
  end
end
