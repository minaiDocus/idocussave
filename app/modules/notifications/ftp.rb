class Notifications::Ftp < Notifications::Notifier
  def initialize(arguments={})
    super
  end

  def notify_ftp_auth_failure
    UniqueJobs.for "FtpAuthFailure - #{@arguments[:ftp].id}", 5.seconds, 5 do
      @arguments[:users].each do |user|
        next unless user.notify.ftp_auth_failure

        @user    = user
        @message = "Votre identifiant et/ou mot de passe sont invalides, veuillez les reconfigurer s'il vous plaît."

        notification = @arguments[:notice_type] == 'org_ftp_auth_failure' ? notify_organization_ftp_auth_failure : notify_user_ftp_auth_failure if user.notifications.where(notice_type: @arguments[:notice_type], is_read: false).where('created_at > ?', 1.day.ago).empty?
      end
    end
  end

  private

  def notify_organization_ftp_auth_failure
    result = create_notification({
      url:         Rails.application.routes.url_helpers.account_organization_url(@arguments[:ftp].organization, { tab: 'ftp' }.merge(ActionMailer::Base.default_url_options)),
      user:        @user,
      notice_type: 'org_ftp_auth_failure',
      title:       'Import/Export FTP - Reconfiguration requise',
      message:     @message
    }, true)

    result[:notification]
  end

  def notify_user_ftp_auth_failure
    result = create_notification({
      url:         Rails.application.routes.url_helpers.account_profile_url({ panel: 'efs_management', anchor: 'ftp' }.merge(ActionMailer::Base.default_url_options)),
      user:        @user,
      notice_type: 'ftp_auth_failure',
      title:       'Livraison FTP - Reconfiguration requise',
      message:     @message
    }, true)

    result[:notification]
  end
end
