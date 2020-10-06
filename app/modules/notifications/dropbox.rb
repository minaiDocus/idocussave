class Notifications::Dropbox < Notifications::Notifier
  def initialize(arguments={})
    super
  end

  def notify_dropbox_invalid_access_token
    UniqueJobs.for "NotifyDropboxErrorWithInvalidAccessToken - #{@arguments[:user].id}", 5.seconds, 5 do
      return if !@arguments[:user].notify.dropbox_invalid_access_token

      notify_dropbox_error_with(
        'dropbox_invalid_access_token',
        'Dropbox - Reconfiguration requise',
        "Votre accès à Dropbox a été révoqué, veuillez le reconfigurer s'il vous plaît."
      )
    end
  end

  def notify_dropbox_insufficient_space
    UniqueJobs.for "NotifyDropboxErrorWithInsufficientSpace - #{@arguments[:user].id}", 5.seconds, 5 do
      return if !@arguments[:user].notify.dropbox_insufficient_space

      notify_dropbox_error_with(
        'dropbox_insufficient_space',
        'Dropbox - Espace insuffisant',
        "Votre compte Dropbox n'a plus d'espace, la livraison automatique a donc été désactivé, veuillez libérer plus d'espace avant de la réactiver."
      )
    end
  end

  private

  def notify_dropbox_error_with(notice_type, title, message)
    if @arguments[:user].notifications.where(notice_type: notice_type).where('created_at > ?', 1.day.ago).first.nil?
      result = create_notification({
        url:         url,
        user:        @arguments[:user],
        notice_type: notice_type,
        title:       title,
        message:     message
      }, true)

      result[:notification]
    else
      false
    end
  end

  def url
    Rails.application.routes.url_helpers.account_profile_url({ panel: 'efs_management', anchor: 'dropbox' }.merge(ActionMailer::Base.default_url_options))
  end
end