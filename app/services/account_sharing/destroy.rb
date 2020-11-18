class AccountSharing::Destroy
  def initialize(account_sharing, requester=nil)
    @account_sharing = account_sharing
    @requester = requester
  end

  def execute
    if @account_sharing.destroy
      FileImport::Dropbox.changed([@account_sharing.collaborator])
      url = Rails.application.routes.url_helpers.account_profile_url({ panel: 'account_sharing' }.merge(ActionMailer::Base.default_url_options))
      if @account_sharing.is_approved

        Notifications::Notifier.new.create_notification({
          url: url,
          user: @account_sharing.collaborator,
          notice_type: 'account_sharing_destroyed',
          title: "Accès à un compte révoqué",
          message: "Votre accès au compte #{@account_sharing.account.info} a été révoqué."
        }, true)
      elsif @requester != @account_sharing.collaborator
        Notifications::Notifier.new.create_notification({
          url: url,
          user: @account_sharing.collaborator,
          notice_type: 'account_sharing_request_canceled',
          title: "Demande d'accès à un compte annulé",
          message: "La demande d'accès au compte #{@account_sharing.account.info} par #{@requester.info} a été annulée."
        }, true)
      else
        collaborators = if @account_sharing.account.manager&.user
          [@account_sharing.account.manager.user]
        else
          @account_sharing.account.organization.admins
        end

        url = Rails.application.routes.url_helpers.account_organization_account_sharings_url(
          @account_sharing.account.organization,
          ActionMailer::Base.default_url_options
        )

        collaborators.each do |collaborator|
           Notifications::Notifier.new.create_notification({
            url: url,
            user: collaborator,
            notice_type: 'account_sharing_request_denied',
            title: "Accès à un compte refusé",
            message: "Votre demande d'accès au compte #{@account_sharing.account.info} a été refusée."
          }, true)
        end
      end
      true
    end
  end
end
