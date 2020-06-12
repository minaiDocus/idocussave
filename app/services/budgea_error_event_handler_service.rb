class BudgeaErrorEventHandlerService
  def execute
    @retrievers_infos = []

    retrievers.each do |retriever|
      client = Budgea::Client.new(retriever.user.budgea_account.try(:access_token))
      initial_state = retriever

      case retriever.budgea_error_message
      when 'SCARequired'
        @connection = client.scaRequired_refresh retriever.budgea_id
      when 'decoupled'
        @connection = client.decoupled_refresh retriever.budgea_id
      else
        #TODO: when we needs others verifications
      end

      retriever.update_state_with(@connection) if @connection.try(:[], 'id') == retriever.budgea_id
      retriever.update(sync_at: Time.parse(@connection['last_update'])) if @connection.present? && @connection['last_update'].present?

      prepare_notification(retriever, initial_state)
    end

    send_notification
  end

  private

  def retrievers
    @retrievers = Retriever.need_refresh
  end

  def prepare_notification(retriever, initial_state)
    @retrievers_infos << {
      initial_state: initial_state.inspect,
      final_state: retriever.reload.inspect
    }
  end

  def send_notification
    log_document = {
        name: "BudgeaErrorEventHandlerService",
        error_group: "[Budgea Error Handler] : SCARequired/Decoupled retrievers",
        erreur_type: "SCARequired/Decoupled retrievers",
        date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
        more_information: {
          lists: @retrievers_infos.join('<br>---------------------------<br>')
        }
      }

    ErrorScriptMailer.error_notification(log_document).deliver if @retrievers_infos.any?
  end
end