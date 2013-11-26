# -*- encoding : UTF-8 -*-
module FiduceoHelper
  def fiduceo_retriever_state(retriever)
    result = FiduceoRetriever.state_machine.states[retriever.state].human_name
    if retriever.error?
      result << ': '
      result << t('mongoid.state_machines.fiduceo_transaction.status.' + retriever.transactions.last.status.downcase)
    end
    result
  end
end
