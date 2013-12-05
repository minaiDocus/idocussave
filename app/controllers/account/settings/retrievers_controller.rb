# -*- encoding : UTF-8 -*-
class Account::Settings::RetrieversController < Account::SettingsController
  before_filter :verify_rights
  before_filter :load_fiduceo_user_id
  before_filter :load_fiduceo_retriever, except: %w(index new create)
  before_filter :load_providers_and_banks, only: %w(new create edit update)

  def index
    @fiduceo_retrievers = search(fiduceo_retriever_contains).order([sort_column,sort_direction]).page(params[:page]).per(params[:per_page])
  end

  def new
    @fiduceo_retriever = FiduceoRetriever.new
  end

  def create
    @fiduceo_retriever = FiduceoRetrieverService.create(@user, fiduceo_retriever_params)
    if @fiduceo_retriever.persisted?
      flash[:success] = 'Créé avec succès.'
      redirect_to account_settings_fiduceo_retrievers_path
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
      redirect_to account_settings_fiduceo_retrievers_path
    else
      render action: :edit
    end
  end

  def destroy
    FiduceoRetrieverService.destroy(@fiduceo_retriever)
    flash[:success] = 'Supprimé avec succès.'
    redirect_to account_settings_fiduceo_retrievers_path
  end

  def fetch
    FiduceoDocumentFetcher.initiate_transactions(@fiduceo_retriever)
    flash[:success] = 'Récupération en cours...'
    redirect_to account_settings_fiduceo_retrievers_path
  end

  def select_documents
    @documents = @fiduceo_retriever.temp_documents.locked.asc(:created_at)
  end

  def update_documents
    rejected_document_ids = params[:document_ids].select { |_,v| v == "0" }.map { |k,_| k }
    rejected_documents = @fiduceo_retriever.temp_documents.any_in(_id: rejected_document_ids)
    rejected_documents.update_all(state: 'rejected')

    document_ids = params[:document_ids].map { |k,_| k }
    documents = @fiduceo_retriever.temp_documents.any_in(_id: document_ids)
    documents.update_all(is_locked: false)

    temp_pack = documents.first.temp_pack
    temp_pack.safely.inc(:document_not_processed_count, -rejected_documents.count)

    @fiduceo_retriever.schedule
    flash[:success] = 'Les documents sélectionnés seront intégrés.'
    redirect_to account_settings_fiduceo_retrievers_path
  end

private

  def verify_rights
    unless @user.is_fiduceo_authorized
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_documents_path
    end
  end

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
    fiduceo_retrievers = fiduceo_retrievers.where(:name => /#{contains[:name]}/i) unless contains[:name].blank?
    fiduceo_retrievers
  end

  def fiduceo_retriever_params
    if action_name == 'update'
      params.require(:fiduceo_retriever).permit(:journal_id, :name, :login, :pass, :param1, :param2, :param3, :is_active)
    else
      params.require(:fiduceo_retriever).permit(:provider_id, :bank_id, :type, :service_name, :journal_id, :name, :login, :pass, :param1, :param2, :param3, :is_active)
    end
  end

  def load_fiduceo_user_id
    @fiduceo_user_id = @user.fiduceo_id || FiduceoUser.new(@user).create
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
