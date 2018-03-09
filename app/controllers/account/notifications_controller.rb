class Account::NotificationsController < Account::AccountController
  skip_before_action :verify_suspension, only: :latest

  def index
    @notifications = @user.notifications.order(is_read: :asc, created_at: :desc).page(params[:page]).per(params[:per_page])
    @notifications.update_all is_read: true, updated_at: Time.now
  end

  def latest
    if organizations_suspended?
      render nothing: true
    else
      render partial: 'layouts/notifications'
    end
  end

  def link_through
    notification = Notification.find params[:id]
    notification.update is_read: true if notification.user == @user
    redirect_to notification.url
  end
end
