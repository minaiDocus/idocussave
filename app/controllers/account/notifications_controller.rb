class Account::NotificationsController < Account::AccountController
  def index
    @notifications = @user.notifications.order(created_at: :desc).page(params[:page]).per(params[:per_page])
    @notifications.update_all is_read: true
  end

  def link_through
    notification = Notification.find params[:id]
    notification.update is_read: true if notification.user == @user
    path = if notification.notice_type.in?(%w(dropbox_invalid_access_token dropbox_insufficient_space))
      account_profile_path panel: 'efs_management', anchor: 'dropbox'
    elsif notification.notice_type == 'ftp_auth_failure'
      account_profile_path panel: 'efs_management', anchor: 'ftp'
    elsif notification.notice_type == 'org_ftp_auth_failure'
      account_organization_path(notification.user.organization, tab: 'ftp')
    elsif notification.notice_type.in?(%w(account_sharing_request))
      account_organization_account_sharings_path notification.user.organization
    elsif notification.notice_type.in?(%w(share_account account_sharing_destroyed account_sharing_request_approved account_sharing_request_denied account_sharing_request_canceled))
      account_profile_path panel: 'account_sharing'
    end
    redirect_to path
  end
end
