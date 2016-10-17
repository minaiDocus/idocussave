# -*- encoding : UTF-8 -*-
class Account::Organization::RetrieversController < Account::Organization::RetrieverController
  before_filter :load_retriever, except: %w(index list new create)
  before_filter :load_providers_and_banks, only: %w(list new create edit update)

  def index
    @retrievers = search(retriever_contains).order_by(sort_column => sort_direction).page(params[:page]).per(params[:per_page])
    render partial: 'account/retrievers/retrievers', locals: { scope: :collaborator } if params[:part].present?
  end

  def list
  end

  def new
    @retriever = Retriever.new
    @retriever.provider_id  = params[:provider_id]
    @retriever.bank_id      = params[:bank_id]
    @retriever.service_name = params[:service_name]
    @retriever.type         = params[:bank_id].present? ? 'bank' : 'provider'
  end

  def create
    @retriever = Retriever.new(retriever_params)
    @retriever.user = @customer
    if @retriever.save
      flash[:success] = 'Création en cours.'
      redirect_to account_organization_customer_retrievers_path(@organization, @customer)
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @retriever.update(retriever_params)
      if @retriever.api_id.present?
        @retriever.udpate_connection
        flash[:success] = 'Modification en cours.'
      else
        @retriever.create_connection
        flash[:success] = 'Création en cours.'
      end
      redirect_to account_organization_customer_retrievers_path(@organization, @customer)
    else
      render :edit
    end
  end

  def destroy
    if @retriever.destroy_connection
      flash[:success] = 'Suppression en cours.'
    else
      flash[:error] = 'Impossible de supprimer.'
    end
    redirect_to account_organization_customer_retrievers_path(@organization, @customer)
  end

  def fetch
    @retriever.synchronize
    flash[:success] = 'Traitement en cours...'
    redirect_to account_organization_customer_retrievers_path(@organization, @customer)
  end

  def waiting_additionnal_info
  end

  def additionnal_info
    # TODO sanitize params[:answers]
    @retriever.answers = params[:answers]
    @retriever.save
    @retriever.update_connection
    flash[:info] = 'Traitement en cours...'
    redirect_to account_organization_customer_retrievers_path(@organization, @customer)
  end

private

  def sort_column
    params[:sort] || 'created_at'
  end
  helper_method :sort_column

  def sort_direction
    params[:direction] || 'desc'
  end
  helper_method :sort_direction

  def retriever_contains
    @contains ||= {}
    if params[:retriever_contains] && @contains.blank?
      @contains = params[:retriever_contains].delete_if do |_,value|
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
  helper_method :retriever_contains

  def search(contains)
    retrievers = @customer.retrievers
    retrievers = retrievers.where(:name => /#{Regexp.quote(contains[:name])}/i) unless contains[:name].blank?
    retrievers
  end

  def retriever_params
    if action_name == 'update'
      params.require(:retriever).permit(:journal_id, :name, :login, :password, :dyn_attr_name, :dyn_attr)
    else
      params.require(:retriever).permit(:provider_id, :bank_id, :type, :service_name, :journal_id, :name, :login, :password, :dyn_attr_name, :dyn_attr)
    end
  end

  def load_retriever
    @retriever = @customer.retrievers.find params[:id]
  end

  def load_providers_and_banks
    list = RetrieverProvider.new
    @providers = list.providers
    @banks = list.banks
  end
end
