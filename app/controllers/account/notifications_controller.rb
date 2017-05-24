class Account::NotificationsController < Account::AccountController
  def index
    @notifications = @user.notifications.order(created_at: :desc).page(params[:page]).per(params[:per_page])
    @notifications.update_all is_read: true
  end

  def link_through
    notification = @user.notifications.find params[:id]
    notification.update is_read: true
    path = case notification.notice_type
    when 'dropbox_invalid_access_token'
      account_profile_path(panel: 'efs_management', anchor: 'dropbox')
    when 'dropbox_insufficient_space'
      account_profile_path(panel: 'efs_management', anchor: 'dropbox')
    end
    redirect_to path
  end
end
