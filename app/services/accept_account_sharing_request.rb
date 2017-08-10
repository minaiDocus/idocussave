class AcceptAccountSharingRequest
  def initialize(account_sharing)
    @account_sharing = account_sharing
  end

  def execute
    @account_sharing.is_approved = true
    @account_sharing.save

    DropboxImport.changed([@account_sharing.collaborator])

    notification = Notification.new
    notification.user        = @account_sharing.collaborator
    notification.notice_type = 'account_sharing_request_approved'
    notification.title       = "Demande d'accès à un dossier accepté"
    notification.message     = "Votre demande d'accès au dossier #{@account_sharing.account.info} a été acceptée."
    NotifyWorker.perform_async(notification.id) if notification.save

    notification2 = Notification.new
    notification2.user        = @account_sharing.account
    notification2.notice_type = 'share_account'
    notification2.title       = 'Partage de compte'
    notification2.message     = "Votre compte est maintenant accéssible par #{@account_sharing.collaborator.info}."
    NotifyWorker.perform_async(notification2.id) if notification2.save
    true
  end
end
