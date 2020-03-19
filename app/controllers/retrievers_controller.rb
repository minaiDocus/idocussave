# frozen_string_literal: true

class RetrieversController < ApiController
  before_action :load_retriever, only: %i[destroy trigger get_retriever_infos]
  before_action :authenticate_current_user, except: %i[callback webauth_callback destroy trigger get_retriever_infos]
  skip_before_action :verify_authenticity_token
  skip_before_action :verify_rights

  def callback
    authorization = request.headers['Authorization']

    if authorization.present? && params['user'] #callback for retrieved data
      access_token = authorization.split[1]
      account = BudgeaAccount.where(identifier: params['user']['id']).first

      if account && account.access_token == access_token
        retrieved_data = RetrievedData.new
        retrieved_data.user = account.user
        retrieved_data.json_content = params.except(:controller, :action)
        retrieved_data.save
        render plain: '', status: :ok
      else
        render plain: '', status: :unauthorized
      end
    else #callback for webauth
      if params[:error_description].present? && params[:error_description] != 'None'
        flash[:error] = params[:error_description].presence || 'Id connection not found'

        redirect_to account_retrievers_path
      elsif params[:id_connection]
        local_params = JSON.parse(Base64.decode64(params[:state])).with_indifferent_access
        remote_params = { id: params[:id_connection], last_update: Time.now.to_s }

        user = User.find local_params[:user_id]
        if user
          CreateBudgeaConnection.new(user, local_params, remote_params).execute
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

      paypal_dom = `curl '#{base_uri}/webauth?#{target}&redirect_uri=#{redirect_uri}&client_id=#{client_id}&state=#{params[:state]}' -H 'Authorization: Bearer #{budgea_account.access_token}'`
      render json: { success: true, paypal_dom: paypal_dom }, status: 200
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
        success = DestroyBudgeaConnection.execute(@retriever)
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
    CreateBudgeaConnection.new(@current_user, params[:data_local], params[:data_remote]).execute
    render json: { success: true }, status: 200
  end

  def destroy
    if params[:success] == 'true' && @retriever.destroy_connection
      success = DestroyBudgeaConnection.execute(@retriever)
    else
      success = false
      @retriever.update(budgea_error_message: params[:error_message])
      @retriever.fail_budgea_connection
    end
    render json: { success: success }, status: 200
  end

  def trigger
    @current_user = @retriever.user
    @retriever.run

    if @retriever.budgea_id && params[:success] == 'true'
      if params[:data_remote][:last_update].present?
        @retriever.sync_at = Time.parse params[:data_remote][:last_update]
      end
      @retriever.save

      if params[:data_remote][:additionnal_fields].present?
        @retriever.pause_budgea_connection
      else
        @retriever.success_budgea_connection
      end

      render json: { success: true }, status: 200
    else
      @retriever.update(budgea_error_message: params[:error_message])
      @retriever.fail_budgea_connection
      render json: { success: false }, status: 200
    end
  end

  def add_infos
    retriever = @current_user.retrievers.where(budgea_id: params[:data_local][:budgea_id]).first
    retriever.synchronize_budgea_connection
    retriever.success_budgea_connection

    render json: { success: true }, status: 200
  end

  def create_bank_accounts
    if CreateBankAccount.execute(@current_user, (params[:accounts].try(:to_unsafe_h) || []), params[:options])
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

  private

  def load_retriever
    @retriever = Retriever.find params[:id]
  end
end