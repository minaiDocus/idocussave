class PonctualScripts::RefreshBudgeaError
  def initialize(retrievers)
    @retrievers = retrievers
  end

  def execute
    counter = 0

    @retrievers.each_with_index do |retriever, index|
      if counter >= 5
        sleep(10)
        counter = 0
      end

      next if !retriever.budgea_error_message.in? ['SCARequired', 'decoupled']

      infos = "#{retriever.id.to_s} ******** #{retriever.budgea_error_message.to_s} ******** #{index} ******** "

      connection = { "error" => retriever.budgea_error_message }
      retriever.update_state_with(connection)

      infos += retriever.reload.budgea_error_message.to_s
      p infos
      LogService.info('ponctual_scripts_budgea_error', infos)

      counter += 1
    end
  end
end