# -*- encoding : UTF-8 -*-
class Account::NewProviderRequestsController < Account::RetrieverController
  before_filter :verify_rights
  before_filter :load_new_provider_request, only: %w(edit update)
  before_filter :verify_if_modifiable

  def index
    @new_provider_requests = search(new_provider_request_contains).order_by(sort_column => sort_direction).page(params[:page]).per(params[:per_page])
  end

  def new
    @new_provider_request = NewProviderRequest.new
  end

  def create
    @new_provider_request = @user.new_provider_requests.build new_provider_request_params
    @new_provider_request.edited_by_customer = true
    if @new_provider_request.save
      flash[:success] = 'Votre demande est prise en compte. Nous vous apporterons une réponse dans les prochains jours.'
      redirect_to account_new_provider_requests_path
    else
      render :new
    end
  end

  def edit
  end

  def update
    @new_provider_request.edited_by_customer = true
    if @new_provider_request.update(new_provider_request_params)
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_new_provider_requests_path
    else
      render :edit
    end
  end

private

  def verify_rights
    unless @user.options.try(:is_retriever_authorized)
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to root_path
    end
  end

  def load_new_provider_request
    @new_provider_request = @user.new_provider_requests.find(params[:id])
  end

  def verify_if_modifiable
    if action_name.in?(%w(edit update)) && !@new_provider_request.pending?
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

  def new_provider_request_contains
    @contains ||= {}
    if params[:new_provider_request_contains] && @contains.blank?
      @contains = params[:new_provider_request_contains].delete_if do |_,value|
        if value.blank? && !value.is_a?(Hash)
          true
        elsif value.is_a? Hash
          value.delete_if { |k,v| v.blank? }
          value.blank?
        else
          false
        end
      end
    end
    @contains
  end
  helper_method :new_provider_request_contains

  def search(contains)
    new_provider_requests = @user.new_provider_requests.not_processed_or_recent
    new_provider_requests = new_provider_requests.where(:name => /#{Regexp.quote(contains[:name])}/i) unless contains[:name].blank?
    new_provider_requests
  end
end
