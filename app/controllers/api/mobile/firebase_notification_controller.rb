class Api::Mobile::FirebaseNotificationController < MobileApiController
  skip_before_action :load_organization
  before_action :load_notifications

  respond_to :json

  def get_notifications
    data_loaded = []
    data_loaded = @notifications.inject([]) do |memo, notif|
      data_loaded += [{
                      id: notif.id,
                      user_id: notif.user_id,
                      is_read: notif.is_read,
                      created_at: notif.created_at,
                      title: notif.title,
                      message: notif.message
                    }]
    end

    render json: {notifications: data_loaded}, status: 200
  end

  def release_new_notifications
    @notifications.update_all is_read: true, updated_at: Time.now
    render json: {success: true}, status: 200
  end

  def register_firebase_token
    FirebaseToken.create_or_initialize(@user, params[:firebase_token], params[:platform]) if params[:firebase_token].present?
    @user.firebase_tokens.each do |token| token.delete_unless_valid end
    render json: {success: true}, status: 200
  end

  private

  def load_notifications
    @notifications = @user.notifications.order(is_read: :asc, created_at: :desc).limit(50)
  end
end
