class BudgeaErrorEventHandlerService
  def initialize
    @retrievers_infos = []
  end

  def execute(retrievers=[])
    sleep_counter = 0

    retrievers.each do |retriever|
      if sleep_counter >= 5
        sleep 10
        sleep_counter = 0
      end

      next if retriever.budgea_connection_successful?

      sleep_counter += 1

      client = Budgea::Client.new(retriever.user.budgea_account.try(:access_token))
      initial_state = retriever.to_json

      case retriever.budgea_error_message
      when 'SCARequired'
        @connection = client.scaRequired_refresh retriever.budgea_id
      when 'decoupled'
        @connection = client.decoupled_refresh retriever.budgea_id
      else
        #TODO: when we needs others verifications
      end

      retriever.update_state_with(@connection) if @connection.try(:[], 'id') == retriever.budgea_id
      retriever.update(sync_at: Time.now)

      prepare_notification(retriever, initial_state)
    end

    send_notification
  end

  private

  def prepare_notification(retriever, initial_state)
    @retrievers_infos << {
      initial_state: initial_state,
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
          lists: @retrievers_infos.join("\n--------------------------------\n")
        }
      }

    ErrorScriptMailer.error_notification(log_document).deliver if @retrievers_infos.any?
  end
end