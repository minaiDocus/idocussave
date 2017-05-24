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
