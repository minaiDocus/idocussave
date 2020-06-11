class BudgeaErrorEventHandlerService
  def execute
    process_refresh_of retrievers if retrievers
  end

  private

  def process_refresh_of(retrievers)
    retrievers.each do |retriever|
      client = Budgea::Client.new(retriever.user.budgea_account.try(:access_token))

      case retriever.budgea_error_message
      when 'SCARequired'
        @connection = client.scaRequired_refresh retriever.budgea_id
      when 'decoupled'
        @connection = client.decoupled_refresh retriever.budgea_id
      else
        #TODO: when we needs others verifications
      end

      retriever.update_state_with(@connection) if @connection
      retriever.update(sync_at: Time.parse(@connection['last_update'])) if @connection.present? && @connection['last_update'].present?
    end
  end

  def retrievers
    @retrievers = Retriever.need_refresh
  end
end