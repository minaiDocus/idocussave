# -*- encoding : UTF-8 -*-
class RetrieverPresenter < BasePresenter
  presents :retriever
  delegate :name, :service_name, :journal, :type, :user, to: :retriever

  def state(scope=:account)
    if retriever.waiting_selection?
      if retriever.provider?
        if scope == :account
          h.link_to 'Sélectionnez vos documents', h.select_account_retrieved_documents_path(document_contains: { retriever_id: retriever }), class: 'btn btn-mini'
        elsif scope == :collaborator
          h.link_to 'Sélectionnez les documents', h.select_account_organization_customer_retrieved_documents_path(user.organization, user, document_contains: { retriever_id: retriever }), class: 'btn btn-mini'
        elsif scope == :admin
          h.content_tag :span, 'Sélection des documents', class: 'label'
        end
      else
        if scope == :account
          h.link_to 'Sélectionnez vos comptes', h.account_bank_accounts_path(bank_account_contains: { retriever_id: retriever }), class: 'btn btn-mini'
        elsif scope == :collaborator
          h.link_to 'Sélectionnez les comptes', h.account_organization_customer_bank_accounts_path(user.organization, user, bank_account_contains: { retriever_id: retriever }), class: 'btn btn-mini'
        elsif scope == :admin
          h.content_tag :span, 'Sélection des comptes', class: 'label'
        end
      end
    elsif retriever.waiting_additionnal_info?
      if scope == :account
        h.link_to "En attente de l'utilisateur", h.waiting_additionnal_info_account_retriever_path(retriever), class: 'btn btn-mini'
      elsif scope == :collaborator
        h.link_to "En attente de l'utilisateur", h.waiting_additionnal_info_account_organization_customer_retriever_path(user.organization, user, retriever), class: 'btn btn-mini'
      elsif scope == :admin
        h.content_tag :span, "En attente de l'utilisateur", class: 'label'
      end
    elsif retriever.creating?
      h.content_tag :span, 'Création en cours', class: 'label'
    elsif retriever.updating?
      h.content_tag :span, 'Mise à jour en cours', class: 'label'
    elsif retriever.synchronizing?
      h.content_tag :span, 'Synchronisation en cours', class: 'label'
    elsif retriever.destroying?
      h.content_tag :span, 'Suppression en cours', class: 'label'
    else
      label_type = 'success'   if retriever.ready?
      label_type = 'important' if retriever.error?
      h.content_tag :span, formatted_state, class: "label label-#{label_type}"
    end
  end

  def action_link(organization=nil, customer=nil)
    if retriever.ready? or retriever.error?
      title = 'Lancer la récupération'
      title = 'Réessayer maintenant' if retriever.error?
      if organization.present?
        url = h.sync_account_organization_customer_retriever_path(organization, customer, retriever)
      else
        url = h.sync_account_retriever_path(retriever)
      end
      h.link_to icon(icon: 'download'), url, data: { method: :post, confirm: t('actions.confirm') }, title: title, rel: 'tooltip'
    else
      ''
    end
  end

private

  def formatted_state
    if retriever.error?
      str = 'Erreur'
      if retriever.error_message.present? && retriever.error_message.size <= 50
        str += ": #{retriever.error_message}"
      end
      str
    else
      Retriever.state_machine.states[retriever.state].human_name
    end
  end
end
