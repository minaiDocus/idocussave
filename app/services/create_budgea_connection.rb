class CreateBudgeaConnection
  def initialize(user, connection_params, budgea_response)
    @user = user
    @attributes = connection_params
    @budgea_response = budgea_response
  end

  def execute
    retriever = @user.retrievers.where(budgea_id: @budgea_response[:id]).first || Retriever.new
    retriever.user = @user
    retriever.sync_at   = Time.parse @budgea_response[:last_update] if @budgea_response[:last_update].present?
    retriever.assign_attributes parse_parameters
    retriever.save

    retriever.configure_budgea_connection

    if @budgea_response[:error].present? && @budgea_response[:error] == "additionalInformationNeeded"
      retriever.pause_budgea_connection
    else
      retriever.synchronize_budgea_connection
      retriever.success_budgea_connection
    end
  end

  def parse_parameters
    data = {}
    data[:capabilities]        = @attributes[:ido_capabilities].split("_")
    data[:budgea_id]           = @budgea_response[:id]
    data[:budgea_connector_id] = @attributes[:ido_connector_id]
    data[:name]                = @attributes[:ido_custom_name]
    data[:service_name]        = @attributes[:ido_connector_name]
    data[:journal_id]          = @attributes[:ido_journal] if @attributes[:ido_journal]
    data
  end
end