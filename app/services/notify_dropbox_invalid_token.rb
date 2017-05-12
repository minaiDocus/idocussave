class NotifyDropboxInvalidToken
  def initialize(user)
    @user = user
  end

  def execute
    notification = Notification.new
    notification.user = @user
    notification.notice_type = 'dropbox_invalid_token'
    if notification.save
      NotifyWorker.perform_async(notification.id)
    end
    notification
  end
end
