class Retriever::CreateBudgeaConnection
  def initialize(user, connection_params, budgea_response)
    @user = user
    @attributes = connection_params
    @budgea_response = budgea_response
  end

  def execute
    retriever = @user.retrievers.where(budgea_id: @budgea_response[:id]).first || Retriever.new
    retriever.user = @user
    retriever.sync_at   = Time.parse @budgea_response[:last_update].to_s if @budgea_response[:last_update].present?
    retriever.assign_attributes parse_parameters

    if retriever.save
      sleep 5
      force = false

      state   = @budgea_response[:error] || @budgea_response[:status]
      message = @budgea_response[:error_message] || @budgea_response[:message] || @budgea_response[:description]

      force = true if message.to_s.match(/You need to give the resume parameter/i)

      log_info = {
        subject: "[Retriever::CreateBudgeaConnection] error on creation",
        name: "ErrorRetriever",
        error_group: "[error-retriever] error on creation",
        erreur_type: "error-retriever - error on creation",
        date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
        more_information: {
          retriever_id: retriever.id,
          retriever_name: retriever.service_name,
          user_code: retriever.user.code,
          connection: @budgea_response.to_json
        }
      }

      ErrorScriptMailer.error_notification(log_info).deliver if state.present?

      retriever.reload.resume_me(force)
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