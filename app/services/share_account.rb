# TODO : need auto test
class ShareAccount
  def initialize(user, authorized_by, params)
    @user          = user
    @authorized_by = authorized_by
    @params        = params
  end

  def execute
    @account_sharing = AccountSharing.new @params
    @account_sharing.organization  = @user.organization
    @account_sharing.authorized_by = @authorized_by
    @account_sharing.is_approved   = true
    authorized = true
    authorized = false unless @account_sharing.collaborator && (@account_sharing.collaborator.is_guest || @account_sharing.collaborator.in?(@user.customers))
    authorized = false unless @account_sharing.account && @account_sharing.account.in?(@user.customers)
    if authorized && @account_sharing.save
      DropboxImport.changed([@account_sharing.collaborator])

      notification = Notification.new
      notification.user        = @account_sharing.collaborator
      notification.notice_type = 'share_account'
      notification.title       = 'Accès à un compte'
      notification.message     = "Vous avez maintenant accès au compte #{@account_sharing.account.info}."
      NotifyWorker.perform_async(notification.id) if notification.save

      notification2 = Notification.new
      notification2.user        = @account_sharing.account
      notification2.notice_type = 'share_account'
      notification2.title       = 'Partage de compte'
      notification2.message     = "Votre compte est maintenant accéssible par #{@account_sharing.collaborator.info}."
      NotifyWorker.perform_async(notification2.id) if notification2.save
    end
    @account_sharing
  end
end
