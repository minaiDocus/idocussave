class Account::NotificationsController < Account::AccountController
  def index
    @notifications = @user.notifications.order(created_at: :desc).page(params[:page]).per(params[:per_page])
    @notifications.update_all is_read: true
  end

  def latest
    render partial: 'layouts/notifications'
  end

  def link_through
    notification = Notification.find params[:id]
    notification.update is_read: true if notification.user == @user
    redirect_to notification.url
  end
end
