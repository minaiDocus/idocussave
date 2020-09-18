class DestroyAccountSharing
  def initialize(account_sharing, requester=nil)
    @account_sharing = account_sharing
    @requester = requester
  end

  def execute
    if @account_sharing.destroy
      DropboxImport.changed([@account_sharing.collaborator])
      url = Rails.application.routes.url_helpers.account_profile_url({ panel: 'account_sharing' }.merge(ActionMailer::Base.default_url_options))
      if @account_sharing.is_approved

        Notifications::Notifier.new.send_notification(
          url,
          @account_sharing.collaborator,
          'account_sharing_destroyed',
          "Accès à un compte révoqué",
          "Votre accès au compte #{@account_sharing.account.info} a été révoqué."
        )
      elsif @requester != @account_sharing.collaborator
        Notifications::Notifier.new.send_notification(
          url,
          @account_sharing.collaborator,
          'account_sharing_request_denied',
          "Demande d'accès à un compte annulé",
          "Votre demande d'accès au compte #{@account_sharing.account.info} a été refusée."
        )
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
           Notifications::Notifier.new.send_notification(
            url,
            collaborator,
            'account_sharing_request_canceled',
            "Accès à un compte refusé",
            "La demande d'accès au compte #{@account_sharing.account.info} par #{@requester.info} a été annulée."
          )
        end
      end
      true
    end
  end
end
