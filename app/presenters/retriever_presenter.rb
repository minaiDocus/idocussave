# -*- encoding : UTF-8 -*-
class RetrieverPresenter < BasePresenter
  presents :retriever
  delegate :name, :service_name, :journal, :user, to: :retriever

  def state(scope=:account)
    if retriever.waiting_selection?
      if retriever.provider? || retriever.provider_and_bank?
        if scope == :account
          h.content_tag :span, 'INFO: En attente de séléction de documents', class: 'badge fs-origin badge-warning'
        elsif scope == :collaborator
          h.content_tag :span, 'INFO: En attente de séléction de documents', class: 'badge fs-origin badge-warning'
        elsif scope == :admin
          h.content_tag :span, 'Sélection des documents', class: 'badge fs-origin badge-secondary'
        end
      else
        if scope == :account
          h.content_tag :span, 'INFO: En attente de séléction de comptes', class: 'badge fs-origin badge-warning'
        elsif scope == :collaborator
          h.content_tag :span, 'INFO: En attente de séléction de comptes', class: 'badge fs-origin badge-warning'
        elsif scope == :admin
          h.content_tag :span, 'Sélection des comptes', class: 'badge fs-origin badge-secondary'
        end
      end
    elsif retriever.waiting_additionnal_info?
      h.content_tag :span, "Information manquante : #{retriever.error_message}", class: 'badge fs-origin badge-warning'
    elsif retriever.configuring? || retriever.running?
      h.content_tag :span, 'Synchronisation en cours', class: 'badge fs-origin badge-secondary'
    elsif retriever.destroying?
      h.content_tag :span, 'Suppression en cours', class: 'badge fs-origin badge-secondary'
    elsif retriever.unavailable?
      content = formatted_state({class: 'badge fs-origin badge-secondary'})
      #Temporary disable new provider request
      # if scope == :account
      #   content + h.link_to("Demander la création d'un automate", h.new_account_new_provider_request_path, class: 'btn btn-light')
      # elsif scope == :collaborator
      #   content + h.link_to("Demander la création d'un automate", h.new_account_organization_customer_new_provider_request_path(user.organization, user), class: 'btn btn-light')
      # elsif scope == :admin
      #   content + h.content_tag(:span, "Demander la création d'un automate", class: 'badge fs-origin badge-secondary')
      # end
    else
      label_type = 'success'  if retriever.ready?
      label_type = 'danger'   if retriever.error?
      label_type = 'warning'  if retriever.error? && retriever.budgea_error_message == 'decoupled'
      formatted_state({class: "badge fs-origin badge-#{label_type}"})
    end
  end

  def action_link(organization=nil, customer=nil)
    if retriever.ready? or retriever.error?
      h.link_to glyphicon('loop-circular'), '#', class: "trigger_retriever trigger_retriever_#{retriever.id} btn btn-light", data: { id: retriever.id }, title: "Synchroniser", rel: 'tooltip'
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

  def formatted_state(options={})
    if retriever.error?
      str = 'Erreur'
      str = 'INFO' if retriever.budgea_error_message == 'decoupled'
      if retriever.error_message.present?
        full_str = "#{str}: #{retriever.error_message}"

        str += retriever.error_message.length < 40 || retriever.budgea_error_message == 'decoupled' ? ": #{retriever.error_message}" : ": #{retriever.error_message.slice(0..40)} ..."
      end
    else
      full_str  = ''
      str       = Retriever.state_machine.states[retriever.state].human_name
    end

    h.content_tag :span, str, class: options[:class], title: full_str
  end
end
