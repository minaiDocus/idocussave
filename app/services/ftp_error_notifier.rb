class FTPErrorNotifier
  def initialize(ftp)
    @ftp = ftp
    @user = @ftp.organization.try(:leader) || @ftp.user
  end

  def auth_failure
    $remote_lock.synchronize("ftp_error_notifier_#{@ftp.id}", expiry: 5.seconds, retries: 5) do
      if @user.notifications.where(notice_type: 'ftp_auth_failure', is_read: false).where('created_at > ?', 1.day.ago).empty?
        notification = Notification.new
        notification.user        = @user
        notification.notice_type = 'ftp_auth_failure'
        notification.title       = 'Import/Export FTP - Reconfiguration requise'
        notification.message     = "Votre identifiant et/ou mot de passe sont invalides, veuillez les reconfigurer s'il vous plaît."
        notification.save
        NotifyWorker.perform_async notification.id
        notification
      else
        false
      end
    end
  end
end
