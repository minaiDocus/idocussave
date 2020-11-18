class AccountSharing::AcceptRequest
  def initialize(account_sharing)
    @account_sharing = account_sharing
  end

  def execute
    @account_sharing.is_approved = true
    @account_sharing.save

    FileImport::Dropbox.changed([@account_sharing.collaborator])

    url = Rails.application.routes.url_helpers.account_profile_url({ panel: 'account_sharing' }.merge(ActionMailer::Base.default_url_options))

    notifications = [
      {
        url:         url,
        user:        @account_sharing.collaborator,
        notice_type: 'account_sharing_request_approved',
        title:       'Partage de compte',
        message:     "Votre compte est maintenant accessible par #{@account_sharing.collaborator.info}."
      },
      {
        url:         url,
        user:        @account_sharing.account,
        notice_type: 'share_account',
        title:       "Demande d'accès à un dossier accepté",
        message:     "Votre demande d'accès au dossier #{@account_sharing.account.info} a été acceptée."
      }
    ]

    notifications.map { |notification| Notifications::Notifier.new.create_notification(notification, true) }

    true
  end
end
