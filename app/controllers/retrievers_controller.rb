# frozen_string_literal: true

class RetrieversController < ApiController
  before_action :load_retriever, only: %i[destroy trigger get_retriever_infos update_budgea_error_message]
  before_action :authenticate_current_user, except: %i[callback destroy trigger get_retriever_infos update_budgea_error_message fetch_webauth_url user_synced user_deleted connection_synced connection_deleted accounts_fetched]
  skip_before_action :verify_authenticity_token
  skip_before_action :verify_rights

  def user_synced
    if params['user'].present? && params["connections"].present?
      retriever = Retriever.where(budgea_id: params["connections"][0]['id']).first
      if retriever
        DataProcessor::RetrievedData.delay.execute(params, "USER_SYNCED", retriever.user)
      else
        retriever_alert(params, 'USER_SYNCED')
      end

      render plain: '', status: :ok
    else
      render json: { success: false, error: 'Erreur de données' }, status: 400
    end
  end

  def user_deleted
    if params["id"].present?
      budgea_account = BudgeaAccount.where(identifier: params["id"]).first

      DataProcessor::RetrievedData.delay.execute(params, "USER_DELETED", budgea_account.try(:user))

      render plain: '', status: :ok
    else
      render json: { success: false, error: 'Erreur de données' }, status: 400
    end
  end

  def connection_deleted
    if params["id_user"].present? && params['id'].present?
      retriever = Retriever.where(budgea_id: params['id']).first
      if retriever
        DataProcessor::RetrievedData.delay.execute(params, "CONNECTION_DELETED", retriever.user)
      else
        retriever_alert(params, 'CONNECTION_DELETED')
      end

      render plain: '', status: :ok
    else
      render json: { success: false, error: 'Erreur de données' }, status: 400
    end
  end

  def callback
    authorization = request.headers['Authorization']
    send_callback_notification(params, authorization) if params.try(:[], 'user').try(:[], 'id').to_i == 210

    if authorization.present? && params['user'] #callback for retrieved data
      access_token = authorization.split[1]
      account = BudgeaAccount.where(identifier: params['user']['id']).first

      if account && (account.access_token == access_token || account.identifer.to_i == 210)
        retrieved_data = RetrievedData.new
        retrieved_data.user = account.user
        retrieved_data.json_content = params.except(:controller, :action)
        retrieved_data.state = 'error'
        retrieved_data.error_message = 'pending webhook'
        retrieved_data.save
        render plain: '', status: :ok
      else
        render plain: '', status: :unauthorized
      end
    else #callback for webauth
      send_webauth_notification(params, 'callback', '', 'callback')

      if params[:error_description].present? && params[:error_description] != 'None'
        flash[:error] = params[:error_description].presence || 'Id connection not found'

        redirect_to account_retrievers_path
      elsif params[:id_connection]
        local_params = JSON.parse(Base64.decode64(params[:state])).with_indifferent_access
        remote_params = { id: params[:id_connection], last_update: Time.now.to_s }

        user = User.find local_params[:user_id]
        if user
          Retriever::CreateBudgeaConnection.new(user, local_params, remote_params).execute
          flash[:success] = 'Paramétrage effectué'
        else
          flash[:error] = 'Modification non autorisée'
        end

        redirect_to account_retrievers_path
      else
        render plain: '', status: :unauthorized
      end
    end
  end

  def fetch_webauth_url
    if params[:id].present? && params[:user_id].present?
      user = User.find params[:user_id]

      budgea_account = user.budgea_account
      redirect_uri = retriever_callback_url
      base_uri = "https://#{Budgea.config.domain}/2.0"
      client_id = Budgea.config.client_id

      target = "id_connection=#{params[:id]}"
      target = "id_connector=#{params[:id]}" if params[:is_new].to_s == 'true'

      url = "curl '#{base_uri}/webauth?#{target}&redirect_uri=#{redirect_uri}&client_id=#{client_id}&state=#{params[:state]}' -H 'Authorization: Bearer #{budgea_account.access_token}'"

      html_dom = `curl '#{base_uri}/webauth?#{target}&redirect_uri=#{redirect_uri}&client_id=#{client_id}&state=#{params[:state]}' -H 'Authorization: Bearer #{budgea_account.access_token}'`

      send_webauth_notification(params, url, html_dom)

      render json: { success: true, html_dom: html_dom }, status: 200
    else
      render json: { success: false, error: 'Erreur de service interne' }, status: 200
    end
  end

  def get_retriever_infos
    user = @retriever.user
    bi_token = user.try(:budgea_account).try(:access_token)

    if params[:remote_method] == 'DELETE' && !@retriever.budgea_id.present?
      success = false
      if @retriever.destroy_connection
        success = Retriever::DestroyBudgeaConnection.execute(@retriever)
      end
      render json: { success: success, deleted: success, bi_token: bi_token, budgea_id: nil }, status: 200
    else
      render json: { success: true, bi_token: bi_token, budgea_id: @retriever.budgea_id }, status: 200
    end
  end

  def create_budgea_user
    account_exist = @current_user.try(:budgea_account).try(:access_token).present?
    success = false

    if !account_exist && params[:data_local][:auth_token].present?
      budgea_account = @current_user.try(:budgea_account) || BudgeaAccount.new
      budgea_account.identifier = params[:data_remote]['0'][:id_user]
      budgea_account.user = @current_user
      budgea_account.access_token = params[:data_local][:auth_token]
      success = budgea_account.save
    end

    error_message = success ? '' : 'Impossible de créer un compte budget insight'
    render json: { success: success, error_message: error_message }, status: 200
  end

  def create
    Retriever::CreateBudgeaConnection.new(@current_user, params[:data_local], params[:data_remote]).execute
    render json: { success: true }, status: 200
  end

  def destroy
    Retriever::DestroyBudgeaConnection.execute(@retriever) if params[:success] == 'true' && @retriever.destroy_connection

    render json: { success: true }, status: 200
  end

  def trigger
    @current_user = @retriever.user

    if @retriever.budgea_id
      @retriever.sync_at = Time.parse(params[:data_remote][:last_update]) if params[:data_remote].present? && params[:data_remote][:last_update].present?

      @retriever.save

      @retriever.update_state_with params_connection

      #TEMP FIX: reload state from resume after trigger
      sleep(2)
      @retriever.reload.resume_me()

      render json: { success: true }, status: 200
    else
      render json: { success: false }, status: 200
    end
  end

  def add_infos
    retriever = @current_user.retrievers.where(budgea_id: params[:data_local][:budgea_id]).first
    sleep 2
    retriever.resume_me

    render json: { success: true }, status: 200
  end

  def create_bank_accounts
    if Transaction::CreateBankAccount.execute(@current_user, (params[:accounts].try(:to_unsafe_h) || []), params[:options])
      render json: { success: true }, status: 200
    else
      render json: { success: false, error_message: 'Impossible de synchroniser un compte bancaire' }, status: 200
    end
  end

  def get_my_accounts
    if params[:data_local][:connector_id].present?
      banks = @current_user.retrievers.where(budgea_id: params[:data_local][:connector_id]).try(:first).try(:bank_accounts).try(:used)
    else
      banks = @current_user.retrievers.linked.map { |r| r.try(:bank_accounts).try(:used) }.compact.flatten
    end

    if params[:data_local][:full_result].present? && params[:data_local][:full_result] == 'true'
      accounts = banks
    else
      accounts = banks.collect(&:api_id) if banks
    end

    render json: { success: true, accounts: accounts || [] }, status: 200
  end

  def update_budgea_error_message
    initial_state = @retriever.to_json

    @retriever.update_state_with params_connection

    sleep(5)

    send_notification(@retriever.reload, initial_state, params_connection)

    render json: { success: true }, status: 200
  end

  private

  def load_retriever
    @retriever = Retriever.find params[:id]
  end

  def params_connection
    _params_tmp = params.dup

    if params[:connections].present?
      params[:connections].each do |k,v|
        _params_tmp.merge!(k=>v) if k != 'id'
      end

      _params_tmp.merge!("connections" => '')
    end

    _params_tmp.merge!("source"=>"RetrieversController")

    _params_tmp
  end

  def send_notification(retriever, initial_state, connection)
    log_document = {
      subject: "[RetrieversController] budgea error event handler service",
      name: "BudgeaErrorEventHandlerService",
      error_group: "[Budgea Error Handler] : SCARequired/decoupled - retrievers",
      erreur_type: "SCARequired/decoupled retrievers",
      date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
      more_information: { real_params: params.to_json.to_s, decoup_params: connection.to_json.to_s },
      raw_information: "<table style='border: 1px solid #CCC;font-family: \"Open Sans\", sans-serif; font-size:12px;'><tbody>
                          <tr><td colspan='2' style='text-align:center; background-color: #BBD8E6;'> #{retriever.id} -- #{connection.try(:[], :id)} </td></tr>
                          <tr><td style='border: 1px solid #CCC;text-align:center;'>Initial</td><td style='border: 1px solid #CCC;'> #{initial_state} </td></tr>
                          <tr style='background-color: #F5F5F5;'><td style='border: 1px solid #CCC;text-align:center;'>Final</td><td style='border: 1px solid #CCC;'> #{retriever.to_json.to_s} </td></tr>
                        </tbody></table>"
    }

    ErrorScriptMailer.error_notification(log_document).deliver
  end

  def send_webauth_notification(parameters, url='', html_dom='', type = 'fetch')
    log_document = {
      subject: "[RetrieversController] budgea webauth retrievers #{type}",
      name: "BudgeaWebAuth",
      error_group: "[Budgea Error Handler] : webAuth - retrievers - #{type}",
      erreur_type: "webAuth retrievers #{type}",
      date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
      more_information: { params: parameters.inspect, url: url.to_s  },
      raw_information: html_dom
    }

    ErrorScriptMailer.error_notification(log_document).deliver
  end

  def send_callback_notification(parameters, access_token)
    log_document = {
      subject: "[RetrieversController] budgea callback retriever",
      name: "BudgeaCallback",
      error_group: "[Budgea Callback] : Callback - retrievers",
      erreur_type: "Callback retriever",
      date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
      more_information: { access_token: access_token, params: parameters.inspect }
    }

    ErrorScriptMailer.error_notification(log_document).deliver
  end

  def retriever_alert(params, type_synced)
    log_document = {
      subject: "[RetrieversController] budgea webhook callback retriever does not exist #{type_synced}",
      name: "BudgeaWebhookCallback",
      error_group: "[Budgea Webhook Callback] : Retriever does not exist - #{type_synced}",
      erreur_type: "retriever does not exist",
      date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
      more_information: { params: params.inspect }
    }

    ErrorScriptMailer.error_notification(log_document).deliver
  end
end