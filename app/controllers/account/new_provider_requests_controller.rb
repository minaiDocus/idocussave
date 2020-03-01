# frozen_string_literal: true

class Account::NewProviderRequestsController < Account::RetrieverController
  before_action :load_budgea_config
  before_action :verif_account

  def index
    @new_provider_requests = @account.new_provider_requests.not_processed_or_recent.order(sort_column => sort_direction).page(params[:page]).per(params[:per_page])
  end

  def new
    redirect_to account_retrievers_path(account_id: @account.id)
    # if params[:create] == '1'
    #   flash[:success] = 'Demande envoyée avec succès'
    #   redirect_to account_new_provider_requests_path
    # else
    #   @new_provider_request = NewProviderRequest.new
    # end
  end

  def create
    redirect_to account_retrievers_path(account_id: @account.id)
    # @new_provider_request = NewProviderRequest.new
    # @new_provider_request = @account.new_provider_requests.build new_provider_request_params
    # @new_provider_request.start_process
    # @new_provider_request.is_sent = true
    # if @new_provider_request.save
    #   render json: { success: true }, status: 200
    # else
    #   render json: { success: false, error_message: 'Impossible de procéder a votre demande, veuillez réessayer plus tard!' }, status: 200
    # end
  end

  private

  def new_provider_request_params
    params.require(:data_local).permit(:name, :url, :email, :login, :types, :description)
  end

  def sort_column
    params[:sort] || 'created_at'
  end
  helper_method :sort_column

  def sort_direction
    params[:direction] || 'desc'
  end
  helper_method :sort_direction

  def load_budgea_config
    bi_config = {
      url: "https://#{Budgea.config.domain}/2.0",
      c_id: Budgea.config.client_id,
      c_ps: Budgea.config.client_secret,
      c_ky: Budgea.config.encryption_key ? Base64.encode64(Budgea.config.encryption_key.to_json.to_s) : '',
      proxy: Budgea.config.proxy
    }.to_json
    @bi_config = Base64.encode64(bi_config.to_s)
  end

  def verif_account
    if @account.nil?
      redirect_to account_retrievers_path
    end
  end
end
