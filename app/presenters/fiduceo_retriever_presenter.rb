# -*- encoding : UTF-8 -*-
class FiduceoRetrieverPresenter < BasePresenter
  presents :fiduceo_retriever
  delegate :name, :service_name, :journal, :type, to: :fiduceo_retriever

  def mode
    fiduceo_retriever.is_auto ? 'Automatique' : 'Manuel'
  end

  def state
    if fiduceo_retriever.is_active
      if fiduceo_retriever.wait_selection?
        if fiduceo_retriever.provider?
          if fiduceo_retriever.pending_document_ids.any?
            h.content_tag :span, 'Preparation des documents', class: 'label'
          else
            h.link_to 'Sélectionnez vos documents', h.select_account_retrieved_documents_path(document_contains: { retriever_id: fiduceo_retriever }), class: 'btn btn-mini'
          end
        else
          h.link_to 'Sélectionnez vos comptes', h.select_bank_accounts_account_fiduceo_retriever_path(fiduceo_retriever), class: 'btn btn-mini'
        end
      elsif fiduceo_retriever.wait_for_user_action?
        h.link_to "En attente de l'utilisateur", h.wait_for_user_action_account_fiduceo_retriever_path(fiduceo_retriever), class: 'btn btn-mini'
      else
        if fiduceo_retriever.processing?
          content = last_event.presence || 'En attente de traitement ...'
          result = h.content_tag :span, content, class: 'label'
        else
          label_type = 'success'   if fiduceo_retriever.scheduled? || fiduceo_retriever.ready?
          label_type = 'important' if fiduceo_retriever.error?
          result = h.content_tag :span, formatted_state, class: "label label-#{label_type}"
        end
        if fiduceo_retriever.error? && fiduceo_retriever.transactions.last.critical_error?
          result += h.content_tag :span, icon(icon: 'warning-sign', title: 'Veuillez contacter le support<support@idocus.com>'), class: 'label'
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

  def action_link
    if fiduceo_retriever.is_active
      if fiduceo_retriever.scheduled? && fiduceo_retriever.provider? or fiduceo_retriever.ready?
        h.link_to icon(icon: 'download'), h.fetch_account_fiduceo_retriever_path(fiduceo_retriever), data: { method: :post, confirm: t('actions.confirm') }, title: 'Lancer la récupération', rel: 'tooltip'
      elsif fiduceo_retriever.error? && fiduceo_retriever.transactions.last.retryable?
        h.link_to icon(icon: 'download'), h.fetch_account_fiduceo_retriever_path(fiduceo_retriever), data: { method: :post, confirm: t('actions.confirm') }, title: 'Réessayer maintenant', rel: 'tooltip'
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
