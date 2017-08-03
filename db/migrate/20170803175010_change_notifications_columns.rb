class ChangeNotificationsColumns < ActiveRecord::Migration
  def change
    change_table :notifications, bulk: true do |t|
      t.column :title, :string
      t.column :message, :text
    end

    remove_reference :notifications, :targetable, polymorphic: true

    Notification.where(notice_type: 'dropbox_invalid_access_token').update_all(
      title: 'Dropbox - Reconfiguration requise',
      message: "Votre accès à Dropbox a été révoqué, veuillez le reconfigurer s'il vous plaît."
    )

    Notification.where(notice_type: 'dropbox_insufficient_space').update_all(
      title: 'Dropbox - Espace insuffisant',
      message: "Votre compte Dropbox n'a plus d'espace, la livraison automatique a donc été désactivé, veuillez libérer plus d'espace avant de la réactiver."
    )
  end
end
