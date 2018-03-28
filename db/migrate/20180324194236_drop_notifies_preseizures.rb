class DropNotifiesPreseizures < ActiveRecord::Migration
  def up
    NotifiableNewPreAssignment.find_each do |n|
      Notifiable.create(notify_id: n.notify_id, notifiable_id: n.preseizure_id, notifiable_type: 'Pack::Report::Preseizure', label: 'new')
    end

    drop_table :notifies_preseizures
  end

  def down
    create_table :notifies_preseizures do |t|
      t.belongs_to :notify
      t.belongs_to :preseizure

      t.index [:notify_id, :preseizure_id], name: 'index_notify_id_preseizure_id'
    end

    Notifiable.new_pre_assignments.find_each do |n|
      NotifiableNewPreAssignment.create(notify_id: n.notify_id, preseizure_id: n.notifiable_id)
    end
  end
end
