class BudgeaErrorEventHandlerService
  def initialize(retriever)
    @retriever = retriever
  end

  def execute
    client          = Budgea::Client.new(@retriever.user.budgea_account.try(:access_token))
    initial_state   = @retriever.to_json

    case @retriever.budgea_error_message
    when 'SCARequired'
      @connection  = client.scaRequired_refresh @retriever.budgea_id
    when 'decoupled'
      @connection = client.decoupled_refresh @retriever.budgea_id
    else
      #TODO: when we needs others verifications
    end

    send_notification(initial_state)

    @connection
  end

  private

  def send_notification(initial_state)
    log_document = {
        name: "BudgeaErrorEventHandlerService",
        error_group: "[Budgea Error Handler] : SCARequired/Decoupled retrievers",
        erreur_type: "SCARequired/Decoupled retrievers",
        date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
        more_information: {
          initial_state: initial_state,
          final_state: @retriever.reload.inspect,
          connection: @connection.inspect
        }
      }

    ErrorScriptMailer.error_notification(log_document).deliver
  end
end