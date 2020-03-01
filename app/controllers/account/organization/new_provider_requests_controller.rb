# frozen_string_literal: true

class Account::Organization::NewProviderRequestsController < Account::Organization::RetrieverController
  before_action :load_new_provider_request, only: %w[edit update]
  before_action :verify_if_modifiable
  before_action :redirect_to_new_page

  def index
    @new_provider_requests = @customer.new_provider_requests.not_processed_or_recent.order(sort_column => sort_direction).page(params[:page]).per(params[:per_page])
  end

  def new
    @new_provider_request = NewProviderRequest.new
  end

  def create
    @new_provider_request = @customer.new_provider_requests.build new_provider_request_params
    @new_provider_request.edited_by_customer = true
    if @new_provider_request.save
      flash[:success] = 'Votre demande est prise en compte. Nous vous apporterons une réponse dans les prochains jours.'
      redirect_to account_organization_customer_new_provider_requests_path(@organization, @customer)
    else
      render :new
    end
  end

  def edit; end

  def update
    @new_provider_request.edited_by_customer = true
    if @new_provider_request.update(new_provider_request_params)
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_organization_customer_new_provider_requests_path(@organization, @customer)
    else
      render :edit
    end
  end

  private

  def load_new_provider_request
    @new_provider_request = @customer.new_provider_requests.find(params[:id])
  end

  def verify_if_modifiable
    if action_name.in?(%w[edit update]) && !@new_provider_request.pending?
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to root_path
    end
  end

  def new_provider_request_params
    params.require(:new_provider_request).permit(:name, :url, :email, :login, :password, :types, :description)
  end

  def sort_column
    params[:sort] || 'created_at'
  end
  helper_method :sort_column

  def sort_direction
    params[:direction] || 'desc'
  end
  helper_method :sort_direction

  def redirect_to_new_page
    redirect_to account_retrievers_path(account_id: @customer.id)
  end
end
