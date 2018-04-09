class NotifyMcfError
  def initialize(users, notice_type)
    @users = Array(users)
    @notice_type = notice_type
  end

  def execute
    @users.each do |user|
      $remote_lock.synchronize("notify_mcf_error_#{user.id}", expiry: 5.seconds, retries: 5) do
        if user.notifications.where(notice_type: @notice_type).where('created_at > ?', 1.day.ago).first.nil?
          notification = Notification.new
          notification.user = user
          notification.notice_type = @notice_type
          if @notice_type == 'mcf_invalid_access_token'
            notification.title   = "My Company Files - Reconfiguration requise"
            notification.message = "Votre accès à My Company Files a été révoqué, veuillez le reconfigurer s'il vous plaît."
          elsif @notice_type == 'mcf_insufficient_space'
            notification.title   = "My Company Files - Espace insuffisant"
            notification.message = "Votre compte My Company Files n'a plus d'espace, la livraison automatique a donc été désactivé, veuillez libérer plus d'espace avant de la réactiver."
          end
          notification.url       = Rails.application.routes.url_helpers.account_organization_url(user.organization, { tab: 'mcf' }.merge(ActionMailer::Base.default_url_options))
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
end
