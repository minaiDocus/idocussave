# -*- encoding : UTF-8 -*-
class RetrieversController < ApiController
  before_filter :load_retriever, only: [:destroy, :trigger, :get_retriever_infos]
  before_filter :authenticate_current_user, except: [:callback, :destroy, :trigger, :get_retriever_infos]
  skip_before_filter :verify_authenticity_token
  skip_before_filter :verify_rights

  def callback
    authorization = request.headers['Authorization']
    if authorization.present? && params['user']
      access_token = authorization.split[1]
      account = BudgeaAccount.where(identifier: params['user']['id']).first
      if account && account.access_token == access_token
        retrieved_data = RetrievedData.new
        retrieved_data.user = account.user
        retrieved_data.json_content = params.except(:controller, :action)
        retrieved_data.save
        render text: '', status: :ok
      else
        render text: '', status: :unauthorized
      end
    else
      render text: '', status: :unauthorized
    end
  end

  def get_retriever_infos
    user = @retriever.user
    bi_token = user.try(:budgea_account).try(:access_token)
    if params[:remote_method] == 'DELETE' && !@retriever.budgea_id.present?
      success = false
      success = DestroyBudgeaConnection.execute(@retriever) if @retriever.destroy_connection
      render json: { success: success, deleted: success, bi_token: bi_token, budgea_id: nil }, status: 200
    else
      render json: { success: bi_token ? true : false, bi_token: bi_token, budgea_id: @retriever.budgea_id }, status: 200
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
    if params[:success] == "true" && @retriever.destroy_connection
      success = DestroyBudgeaConnection.execute(@retriever)
    else
      success = false
      @retriever.update(budgea_error_message: params[:error_message])
      @retriever.fail_budgea_connection
    end
    render json: { success: success  }, status: 200
  end

  def trigger
    @current_user = @retriever.user
    @retriever.run
    if @retriever.budgea_id && params[:success] == "true"
      @retriever.sync_at = Time.parse params[:data_remote][:last_update] if params[:data_remote][:last_update].present?
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
    if CreateBankAccount.execute(@current_user, params[:connector_id], (params[:accounts] || []))
      render json: { success: true }, status: 200
    else
      render json: { success: false, error_message: 'Impossible de synchroniser un compte bancaire' }, status: 200
    end
  end

  def get_my_accounts
    banks = @current_user.retrievers.where(budgea_id: params[:data_local][:connector_id]).try(:first).try(:bank_accounts).try(:used)
    accounts = banks.collect(&:api_id) if banks
    render json: { success: true, accounts: accounts || [] }, status: 200
  end

  private

  def load_retriever
    @retriever = Retriever.find params[:id]
  end
end
