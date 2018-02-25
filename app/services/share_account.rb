class ShareAccount
  def initialize(requester, params, authorized_by=nil)
    @requester     = requester
    @authorized_by = authorized_by
    @params        = params
  end

  def execute
    @account_sharing = AccountSharing.new @params
    @account_sharing.organization  = @requester.organization
    @account_sharing.authorized_by = authorized_by
    @account_sharing.is_approved   = true
    authorized = true
    authorized = false unless @account_sharing.collaborator && (@account_sharing.collaborator.is_guest || @account_sharing.collaborator.in?(@requester.customers))
    authorized = false unless @account_sharing.account && @account_sharing.account.in?(@requester.customers)
    if authorized && @account_sharing.save
      DropboxImport.changed([@account_sharing.collaborator])

      url = Rails.application.routes.url_helpers.account_profile_url({ panel: 'account_sharing' }.merge(ActionMailer::Base.default_url_options))

      notification = Notification.new
      notification.user        = @account_sharing.collaborator
      notification.notice_type = 'share_account'
      notification.title       = 'Accès à un compte'
      notification.message     = "Vous avez maintenant accès au compte #{@account_sharing.account.info}."
      notification.url         = url
      NotifyWorker.perform_async(notification.id) if notification.save

      notification2 = Notification.new
      notification2.user        = @account_sharing.account
      notification2.notice_type = 'share_account'
      notification2.title       = 'Partage de compte'
      notification2.message     = "Votre compte est maintenant accessible par #{@account_sharing.collaborator.info}."
      notification2.url         = url
      NotifyWorker.perform_async(notification2.id) if notification2.save
    end
    @account_sharing
  end

  def authorized_by
    if @authorized_by
      @authorized_by
    elsif @requester.class == Collaborator
      @requester.user
    else
      @requester
    end
  end
end
