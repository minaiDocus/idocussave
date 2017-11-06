class NotifyDropboxError
  def initialize(user, notice_type)
    @user = user
    @notice_type = notice_type
  end

  def execute
    $remote_lock.synchronize('notify_dropbox_error', expiry: 5.seconds, retries: 5) do
      if @user.notifications.where(notice_type: @notice_type).where('created_at > ?', 1.day.ago).first.nil?
        notification = Notification.new
        notification.user = @user
        notification.notice_type = @notice_type
        if @notice_type == 'dropbox_invalid_access_token'
          notification.title   = "Dropbox - Reconfiguration requise"
          notification.message = "Votre accès à Dropbox a été révoqué, veuillez le reconfigurer s'il vous plaît."
        elsif @notice_type == 'dropbox_insufficient_space'
          notification.title   = "Dropbox - Espace insuffisant"
          notification.message = "Votre compte Dropbox n'a plus d'espace, la livraison automatique a donc été désactivé, veuillez libérer plus d'espace avant de la réactiver."
        end
        notification.url       = Rails.application.routes.url_helpers.account_profile_url({ panel: 'efs_management', anchor: 'dropbox' }.merge(ActionMailer::Base.default_url_options))
        if notification.save
          NotifyWorker.perform_async(notification.id)
        end
        notification
      else
        false
      end
    end
  end
end
