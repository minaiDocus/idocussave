# -*- encoding : UTF-8 -*-
class RetrieverPresenter < BasePresenter
  presents :retriever
  delegate :name, :service_name, :journal, :user, to: :retriever

  def state(scope=:account)
    if retriever.waiting_selection?
      if retriever.provider? || retriever.provider_and_bank?
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
    elsif retriever.configuring? || retriever.running?
      h.content_tag :span, 'Synchronisation en cours', class: 'label'
    elsif retriever.destroying?
      h.content_tag :span, 'Suppression en cours', class: 'label'
    elsif retriever.unavailable?
      content = h.content_tag :span, formatted_state, class: 'label'
      if scope == :account
        content + h.link_to("Demander la création d'un automate", h.new_account_new_provider_request_path, class: 'btn btn-mini')
      elsif scope == :collaborator
        content + h.link_to("Demander la création d'un automate", h.new_account_organization_customer_new_provider_request_path(user.organization, user), class: 'btn btn-mini')
      elsif scope == :admin
        content + h.content_tag(:span, "Demander la création d'un automate", class: 'label')
      end
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
      h.link_to icon(icon: 'download'), '#', class: 'trigger_retriever', data: { id: retriever.id }, title: title, rel: 'tooltip'
    else
      ''
    end
  end

  def capabilities
    if retriever.provider_and_bank?
      'Doc. et Op. Bancaires'
    elsif retriever.provider?
      'Documents'
    elsif retriever.bank?
      'Op. bancaires'
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
