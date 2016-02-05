# -*- encoding : UTF-8 -*-
class Account::RetrieversController < Account::FiduceoController
  before_filter :load_fiduceo_user_id
  before_filter :load_fiduceo_retriever, except: %w(index list new create)
  before_filter :load_providers_and_banks, only: %w(list new create edit update)

  def index
    @fiduceo_retrievers = search(fiduceo_retriever_contains).order_by(sort_column => sort_direction).page(params[:page]).per(params[:per_page])
    @is_filter_empty = fiduceo_retriever_contains.empty?
    render partial: 'retrievers' if params[:part].present?
  end

  def list
  end

  def new
    @fiduceo_retriever = FiduceoRetriever.new
    @fiduceo_retriever.provider_id  = params[:provider_id]
    @fiduceo_retriever.bank_id      = params[:bank_id]
    @fiduceo_retriever.service_name = params[:service_name]
    @fiduceo_retriever.type         = params[:bank_id].present? ? 'bank' : 'provider'
  end

  def create
    @fiduceo_retriever = FiduceoRetrieverService.create(@user, fiduceo_retriever_params)
    if @fiduceo_retriever.persisted?
      flash[:success] = 'Créé avec succès.'
      redirect_to account_fiduceo_retrievers_path
    else
      render action: :new
    end
  end

  def edit
  end

  def update
    @fiduceo_retriever = FiduceoRetrieverService.update(@fiduceo_retriever, fiduceo_retriever_params)
    if @fiduceo_retriever.valid?
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_fiduceo_retrievers_path
    else
      render action: :edit
    end
  end

  def destroy
    if FiduceoRetrieverService.destroy(@fiduceo_retriever)
      flash[:success] = 'Supprimé avec succès.'
    else
      flash[:error] = 'Impossible de supprimer.'
    end
    redirect_to account_fiduceo_retrievers_path
  end

  def fetch
    @fiduceo_retriever.schedule if @fiduceo_retriever.error?
    FiduceoDocumentFetcher.initiate_transactions(@fiduceo_retriever)
    flash[:success] = 'Traitement en cours...'
    redirect_to account_fiduceo_retrievers_path
  end

  def wait_for_user_action
    transaction = @fiduceo_retriever.transactions.last
    @questions = transaction.wait_for_user_labels
  end

  def update_transaction
    transaction = @fiduceo_retriever.transactions.last
    if FiduceoDocumentFetcher.send_additionnal_information(transaction, params[:answers])
      @fiduceo_retriever.fetch
      flash[:info] = 'Poursuite de la transaction'
      redirect_to account_fiduceo_retrievers_path
    else
      @questions = transaction.wait_for_user_labels
      flash[:error] = "Impossible d'enregistrer les modifications."
      render action: 'wait_for_user_action'
    end
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

  def fiduceo_retriever_contains
    @contains ||= {}
    if params[:fiduceo_retriever_contains] && @contains.blank?
      @contains = params[:fiduceo_retriever_contains].delete_if do |_,value|
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
  helper_method :fiduceo_retriever_contains

  def search(contains)
    fiduceo_retrievers = @user.fiduceo_retrievers
    fiduceo_retrievers = fiduceo_retrievers.where(:name => /#{Regexp.quote(contains[:name])}/i) unless contains[:name].blank?
    fiduceo_retrievers
  end

  def fiduceo_retriever_params
    if action_name == 'update'
      params.require(:fiduceo_retriever).permit(:journal_id, :name, :login, :pass, :param1, :param2, :param3, :is_active)
    else
      params.require(:fiduceo_retriever).permit(:provider_id, :bank_id, :type, :service_name, :journal_id, :name, :login, :pass, :param1, :param2, :param3, :is_active)
    end
  end

  def load_fiduceo_retriever
    @fiduceo_retriever = FiduceoRetriever.find params[:id]
  end

  def load_providers_and_banks
    fiduceo_provider = FiduceoProvider.new(@fiduceo_user_id)
    @providers = fiduceo_provider.providers
    @banks = fiduceo_provider.banks
  end
end
