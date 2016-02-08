# -*- encoding : UTF-8 -*-
class FiduceoRetrieverPresenter < BasePresenter
  presents :fiduceo_retriever
  delegate :name, :service_name, :journal, :type, :transaction_status, :user, to: :fiduceo_retriever

  def mode
    fiduceo_retriever.is_auto ? 'Automatique' : 'Manuel'
  end

  def state(scope=:account)
    if fiduceo_retriever.is_active
      if fiduceo_retriever.wait_selection?
        if fiduceo_retriever.provider?
          if fiduceo_retriever.pending_document_ids.any?
            h.content_tag :span, 'Preparation des documents', class: 'label'
          else
            if scope == :account
              h.link_to 'Sélectionnez vos documents', h.select_account_retrieved_documents_path(document_contains: { retriever_id: fiduceo_retriever }), class: 'btn btn-mini'
            elsif scope == :collaborator
              h.link_to 'Sélectionnez les documents', h.select_account_organization_customer_retrieved_documents_path(user.organization, user, document_contains: { retriever_id: fiduceo_retriever }), class: 'btn btn-mini'
            elsif scope == :admin
              h.content_tag :span, 'Sélection des documents', class: 'label'
            end
          end
        else
          if scope == :account
            h.link_to 'Sélectionnez vos comptes', h.account_bank_accounts_path(bank_account_contains: { retriever_id: fiduceo_retriever }), class: 'btn btn-mini'
          elsif scope == :collaborator
            h.link_to 'Sélectionnez les comptes', h.account_organization_customer_bank_accounts_path(user.organization, user, bank_account_contains: { retriever_id: fiduceo_retriever }), class: 'btn btn-mini'
          elsif scope == :admin
            h.content_tag :span, 'Sélection des comptes', class: 'label'
          end
        end
      elsif fiduceo_retriever.wait_for_user_action?
        if scope == :account
          h.link_to "En attente de l'utilisateur", h.wait_for_user_action_account_fiduceo_retriever_path(fiduceo_retriever), class: 'btn btn-mini'
        elsif scope == :collaborator
          h.link_to "En attente de l'utilisateur", h.wait_for_user_action_account_organization_customer_fiduceo_retriever_path(user.organization, user, fiduceo_retriever), class: 'btn btn-mini'
        elsif scope == :admin
          h.content_tag :span, "En attente de l'utilisateur", class: 'label'
        end
      else
        if fiduceo_retriever.processing?
          content = last_event.presence || 'En attente de traitement ...'
          result = h.content_tag :span, content, class: 'label'
        else
          label_type = 'success'   if fiduceo_retriever.scheduled? || fiduceo_retriever.ready?
          label_type = 'important' if fiduceo_retriever.error?
          result = h.content_tag :span, class: "label label-#{label_type}" do
            concat formatted_state
            if fiduceo_retriever.transaction_status == 'CHECK_ACCOUNT'
              concat(h.content_tag :i, '', class: 'icon-info-sign', style: 'margin-left:3px;', title: last_event.gsub(/\AErreur : /, ''))
            end
          end
        end
        result
      end
    else
      h.content_tag :span, t('mongoid.state_machines.fiduceo_retriever.states.disabled'), class: 'label'
    end
  end

  def events
    fiduceo_retriever.transactions.last.events
  end

  def action_link(organization=nil, customer=nil)
    if fiduceo_retriever.is_active
      if fiduceo_retriever.scheduled? or fiduceo_retriever.ready? or fiduceo_retriever.error?
        title = 'Lancer la récupération'
        title = 'Réessayer maintenant' if fiduceo_retriever.error?
        if organization.present?
          url = h.fetch_account_organization_customer_fiduceo_retriever_path(organization, customer, fiduceo_retriever)
        else
          url = h.fetch_account_fiduceo_retriever_path(fiduceo_retriever)
        end
        h.link_to icon(icon: 'download'), url, data: { method: :post, confirm: t('actions.confirm') }, title: title, rel: 'tooltip'
      else
        ''
      end
    else
      ''
    end
  end

private

  def formatted_state
    if fiduceo_retriever.error?
      t('mongoid.state_machines.fiduceo_transaction.status.' + fiduceo_retriever.transactions.last.status.downcase).capitalize
    else
      FiduceoRetriever.state_machine.states[fiduceo_retriever.state].human_name
    end
  end

  def last_event
    fiduceo_retriever.transactions.last.try(:events).try(:[], 'lastUserInfo')
  end

  def formatted_events
    if (_events = fiduceo_retriever.transactions.last.events['transactionEvent'])
      if _events.is_a? Hash
        _events['status']
      else
        _events.map do |event|
          event['status']
        end.join('<br>')
      end
    else
      ''
    end
  end
end
