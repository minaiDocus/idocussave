class ShareMyAccount
  def initialize(user, params, current_user=nil)
    @user = user
    @params = params
    @authorized_by = current_user || user
  end

  def execute
    @account_sharing = AccountSharing.new
    if collaborator.persisted?
      @account_sharing.account       = @user
      @account_sharing.collaborator  = collaborator
      @account_sharing.organization  = @user.organization
      @account_sharing.authorized_by = @authorized_by
      @account_sharing.is_approved   = true
      if @account_sharing.save
        DropboxImport.changed([@account_sharing.collaborator])

        notification = Notification.new
        notification.user        = @account_sharing.collaborator
        notification.notice_type = 'share_account'
        notification.title       = 'Accès à un compte'
        notification.message     = "Vous avez maintenant accès au compte #{@account_sharing.account.info}."
        notification.url         = Rails.application.routes.url_helpers.account_profile_url({ panel: 'account_sharing' }.merge(ActionMailer::Base.default_url_options))
        NotifyWorker.perform_async(notification.id) if notification.save
      end
    end
    [collaborator, @account_sharing]
  end

private

  def collaborator
    if @collaborator
      @collaborator
    else
      @collaborator = User.where(is_prescriber: false, email: @params[:email]).first
      @collaborator ||= CreateContact.new(@params, @user.organization).execute
      @collaborator
    end
  end
end
