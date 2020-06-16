class BudgeaErrorEventHandlerService
  def execute
    ['SCARequired', 'decoupled'].each do |budgea_error_type|
      @retrievers_infos = []

      retrievers = Retriever.where(budgea_error_message: budgea_error_type)

      sleep_counter = 0
      retrievers.each do |retriever|
        if sleep_counter >= 5
          sleep 10
          sleep_counter = 0
        end

        next if retriever.budgea_connection_successful?

        client        = Budgea::Client.new(retriever.user.budgea_account.try(:access_token))
        initial_state = retriever.to_json

        begin
          case retriever.budgea_error_message
          when 'SCARequired'
            @connection = client.scaRequired_refresh retriever.budgea_id
          when 'decoupled'
            @connection = client.decoupled_refresh retriever.budgea_id
          else
            #TODO: when we needs others verifications
          end
        rescue => e
          @connection = { 'rescue' => e.to_s }
        end

        retriever.update_state_with(@connection, false) if @connection.try(:[], 'id') == retriever.budgea_id

        prepare_notification(retriever, initial_state, @connection)
        sleep_counter += 1
      end

      send_notification(budgea_error_type)

      sleep 60
    end
  end

  private

  def prepare_notification(retriever, initial_state, connection)
    @retrievers_infos << {
      initial_state: initial_state,
      final_state: retriever.reload,
      connection: connection
    }
  end

  def notification_to_html
    html = "<table><tbody>"

    @retrievers_infos.each do |info|
      html += " <tr><td colspan='2' style='text-align:center; background-color: #CCC;'> #{info[:final_state].id} </td></tr>
                <tr><td>Initial</td><td> #{info[:initial_state]} </td></tr>
                <tr><td>Final</td><td> #{info[:final_state].to_json.to_s} </td></tr>
                <tr><td>Connection</td><td> #{info[:connection]} </td></tr>"
    end
    html += "</tbody></table>"
  end

  def send_notification(budgea_error_type)
    log_document = {
      name: "BudgeaErrorEventHandlerService",
      error_group: "[Budgea Error Handler] : #{budgea_error_type} - retrievers",
      erreur_type: "#{budgea_error_type} retrievers",
      date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
      raw_information: notification_to_html
    }

    ErrorScriptMailer.error_notification(log_document).deliver if @retrievers_infos.any?
  end
end
