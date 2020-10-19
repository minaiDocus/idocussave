class Notifications::McfDocuments < Notifications::Notifier
  def initialize(arguments={})
    super
  end

  def notify_mcf_document_with_process_error
    mcf_documents = McfDocument.not_processable_and_not_notified

    return unless mcf_documents.size > 0

    mcf_documents.group_by(&:user_id).each do |mcf_docs|
      customer = User.find mcf_docs.first
      mcf_docs_count = mcf_docs.last.size

      collaborators = customer.prescribers
      if collaborators.any?
        collaborators.each do |collaborator|
          collab = Collaborator.new(collaborator)

          message = if mcf_docs_count == 1
            "- 1 document venant de MCF n'a pas pu être récupéré pour le dossier : #{customer.code} \n"
          else
            "- #{mcf_docs_count} documents venant de MCF n'ont pas pu être récupérés pour le dossier : #{customer.code} \n"
          end

          create_notification({
            url:         Rails.application.routes.url_helpers.account_organization_customers_url(collab.organization, ActionMailer::Base.default_url_options),
            user:        collaborator,
            notice_type: 'mcf_document_errors',
            title:       "documents mcf, non récupérés",
            message:     message
          }, collaborator.try(:notify).try(:mcf_document_errors))
        end
      end
    end

    mcf_documents.each do |mcf_document|
      mcf_document.update(is_notified: true)
    end
  end

  def notify_mcf_invalid_access_token
    title   = "My Company Files - Reconfiguration requise"
    message = "Votre accès à My Company Files a été révoqué, veuillez le reconfigurer s'il vous plaît."

    notify_mcf_document_error_with('mcf_invalid_access_token', title, message)
  end

  def notify_mcf_insufficient_space
    title   = "My Company Files - Espace insuffisant"
    message = "Votre compte My Company Files n'a plus d'espace, la livraison automatique a donc été désactivé, veuillez libérer plus d'espace avant de la réactiver."

    notify_mcf_document_error_with('mcf_insufficient_space', title, message)
  end

  private

  def notify_mcf_document_error_with(notice_type, title, message)
    @arguments[:users].each do |user|
      @user = user
      UniqueJobs.for "NotifyMcfDocumentError - #{@user.id}", 5.seconds, 5 do
        if user.notifications.where(notice_type: notice_type).where('created_at > ?', 1.day.ago).first.nil?
          result = create_notification({ url: url, user: @user, notice_type: notice_type, title: title, message: message }, true)
          result[:notification]
        else
          false
        end
      end
    end
  end

  def url
    Rails.application.routes.url_helpers.account_organization_url(@user.organization, { tab: 'mcf' }.merge(ActionMailer::Base.default_url_options))
  end
end