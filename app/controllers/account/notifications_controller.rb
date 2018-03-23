class Account::NotificationsController < Account::AccountController
  before_action :load_notifications, except: :link_through

  def index
    @notifications.update_all is_read: true, updated_at: Time.now
  end

  def latest
    render partial: 'notifications', layout: false, locals: { notifications: @notifications }
  end

  def link_through
    notification = Notification.find params[:id]
    notification.update is_read: true if notification.user == @user
    redirect_to notification.url
  end

  private

  def load_notifications
    @notifications = @user.notifications.order(is_read: :asc, created_at: :desc).page(params[:page]).per(params[:per_page])
  end
end
