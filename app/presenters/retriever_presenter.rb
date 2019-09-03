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
      if organization.present?
        url = h.run_account_organization_customer_retriever_path(organization, customer, retriever)
      else
        url = h.run_account_retriever_path(retriever)
      end
      h.link_to icon(icon: 'download'), url, data: { method: :post, confirm: t('actions.confirm') }, title: title, rel: 'tooltip'
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

  def fiduceo_state
    if retriever.fiduceo_connection_not_configured?
      '-'
    elsif retriever.fiduceo_connection_successful?
      icon_ok
    elsif retriever.fiduceo_connection_failed?
      icon_not_ok
    else
      icon_refresh
    end
  end

  def budgea_state
    if retriever.budgea_connection_not_configured?
      '-'
    elsif retriever.budgea_connection_successful?
      icon_ok
    elsif retriever.budgea_connection_failed?
      icon_not_ok
    else
      icon_refresh
    end
  end

private

  def formatted_state(options={})
    if retriever.error?
      str = 'Erreur'
      if retriever.error_message.present?
        full_str = "#{str}: #{retriever.error_message}"

        str += retriever.error_message.length < 40 ? ": #{retriever.error_message}" : ": #{retriever.error_message.slice(0..40)} ..."
      end
    else
      full_str  = ''
      str       = Retriever.state_machine.states[retriever.state].human_name
    end

    h.content_tag :span, str, class: options[:class], title: full_str
  end
end
