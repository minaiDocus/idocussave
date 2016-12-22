# -*- encoding : UTF-8 -*-
class Account::RetrieversController < Account::FiduceoController
  before_filter :load_fiduceo_user_id
  before_filter :load_fiduceo_retriever,   except: %w(index list new create)
  before_filter :load_providers_and_banks, only: %w(list new create edit update)


  # GET /account/retrievers
  def index
    @fiduceo_retrievers = FiduceoRetriever.search_for_collection(@user.fiduceo_retrievers, search_terms(params[:fiduceo_retriever_contains])).order(sort_column => sort_direction).page(params[:page]).per(params[:per_page])

    @is_filter_empty = search_terms(params[:fiduceo_retriever_contains]).empty?

    render partial: 'retrievers', locals: { scope: :account } if params[:part].present?
  end


  # GET /account/retrievers/list
  def list
  end


  # GET /account/retrievers/new
  def new
    @fiduceo_retriever = FiduceoRetriever.new

    @fiduceo_retriever.type         = params[:bank_id].present? ? 'bank' : 'provider'
    @fiduceo_retriever.bank_id      = params[:bank_id]
    @fiduceo_retriever.provider_id  = params[:provider_id]
    @fiduceo_retriever.service_name = params[:service_name]
  end


  # POST /account/retrievers
  def create
    @fiduceo_retriever = FiduceoRetrieverService.create(@user, fiduceo_retriever_params)

    if @fiduceo_retriever.persisted?
      flash[:success] = 'Créé avec succès.'

      redirect_to account_fiduceo_retrievers_path
    else
      render :new
    end
  end


  # GET /account/retrievers/:id/edit
  def edit
  end


  # PUT /account/retrievers/:id
  def update
    @fiduceo_retriever = FiduceoRetrieverService.update(@fiduceo_retriever, fiduceo_retriever_params)

    if @fiduceo_retriever.valid?
      flash[:success] = 'Modifié avec succès.'

      redirect_to account_fiduceo_retrievers_path
    else
      render :edit
    end
  end


  # DELETE /account/retrievers/:id
  def destroy
    if FiduceoRetrieverService.destroy(@fiduceo_retriever)
      flash[:success] = 'Supprimé avec succès.'
    else
      flash[:error] = 'Impossible de supprimer.'
    end

    redirect_to account_fiduceo_retrievers_path
  end


  # GET /account/retrievers/:id/fetch
  def fetch
    @fiduceo_retriever.schedule if @fiduceo_retriever.error?

    FiduceoDocumentFetcher.initiate_transactions(@fiduceo_retriever)

    flash[:success] = 'Traitement en cours...'

    redirect_to account_fiduceo_retrievers_path
  end


  # GET /account/retrievers/:id/wait_for_user_action
  def wait_for_user_action
    transaction = @fiduceo_retriever.transactions.last

    @questions = transaction.wait_for_user_labels
  end


  # PUT # GET /account/retrievers/:id/id/update_transaction
  def update_transaction
    transaction = @fiduceo_retriever.transactions.last

    if FiduceoDocumentFetcher.send_additionnal_information(transaction, params[:answers])
      @fiduceo_retriever.fetch

      flash[:info] = 'Poursuite de la transaction'

      redirect_to account_fiduceo_retrievers_path
    else
      @questions = transaction.wait_for_user_labels

      flash[:error] = "Impossible d'enregistrer les modifications."

      render :wait_for_user_action
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


  def fiduceo_retriever_params
    if action_name == 'update'
      params.require(:fiduceo_retriever).permit(:journal_id, :name, :login, :pass, :param1, :param2, :param3, :is_active)
    else
      params.require(:fiduceo_retriever).permit(:provider_id, :bank_id, :type, :service_name, :journal_id, :name, :login, :pass, :param1, :param2, :param3, :is_active)
    end
  end


  def load_fiduceo_retriever
    @fiduceo_retriever = @user.fiduceo_retrievers.find params[:id]
  end


  def load_providers_and_banks
    fiduceo_provider = FiduceoProvider.new(@fiduceo_user_id)

    @providers = fiduceo_provider.providers

    @banks = fiduceo_provider.banks
  end
end
