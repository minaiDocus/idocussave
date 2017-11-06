class DestroyAccountSharing
  def initialize(account_sharing, requester=nil)
    @account_sharing = account_sharing
    @requester = requester
  end

  def execute
    if @account_sharing.destroy
      DropboxImport.changed([@account_sharing.collaborator])

      notification = Notification.new
      notification.url = Rails.application.routes.url_helpers.account_profile_url({ panel: 'account_sharing' }.merge(ActionMailer::Base.default_url_options))
      if @account_sharing.is_approved
        notification.user        = @account_sharing.collaborator
        notification.notice_type = 'account_sharing_destroyed'
        notification.title       = 'Accès à un compte révoqué'
        notification.message     = "Votre accès au compte #{@account_sharing.account.info} a été révoqué."
      elsif @requester == @account_sharing.collaborator
        notification.user        = @account_sharing.account.parent || @account_sharing.account.organization.leader
        notification.notice_type = 'account_sharing_request_canceled'
        notification.title       = "Demande d'accès à un compte annulé"
        notification.message     = "La demande d'accès au compte #{@account_sharing.account.info} par #{@requester.info} a été annulée."
      else
        notification.user        = @account_sharing.collaborator
        notification.notice_type = 'account_sharing_request_denied'
        notification.title       = 'Accès à un compte refusé'
        notification.message     = "Votre demande d'accès au compte #{@account_sharing.account.info} a été refusée."
      end
      NotifyWorker.perform_async(notification.id) if notification.save
      true
    end
  end
end
