class AcceptAccountSharingRequest
  def initialize(account_sharing)
    @account_sharing = account_sharing
  end

  def execute
    @account_sharing.is_approved = true
    @account_sharing.save

    DropboxImport.changed([@account_sharing.collaborator])

    url = Rails.application.routes.url_helpers.account_profile_url({ panel: 'account_sharing' }.merge(ActionMailer::Base.default_url_options))

    notification = Notification.new
    notification.user        = @account_sharing.collaborator
    notification.notice_type = 'account_sharing_request_approved'
    notification.title       = "Demande d'accès à un dossier accepté"
    notification.message     = "Votre demande d'accès au dossier #{@account_sharing.account.info} a été acceptée."
    notification.url         = url
    NotifyWorker.perform_async(notification.id) if notification.save

    notification2 = Notification.new
    notification2.user        = @account_sharing.account
    notification2.notice_type = 'share_account'
    notification2.title       = 'Partage de compte'
    notification2.message     = "Votre compte est maintenant accessible par #{@account_sharing.collaborator.info}."
    notification2.url         = url
    NotifyWorker.perform_async(notification2.id) if notification2.save
    true
  end
end
