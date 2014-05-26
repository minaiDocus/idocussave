# -*- encoding : UTF-8 -*-
class Account::RetrieversController < Account::FiduceoController
  before_filter :load_fiduceo_user_id
  before_filter :load_fiduceo_retriever, except: %w(index list new create)
  before_filter :verify_selection, only: %w(select_bank_accounts create_bank_accounts)
  before_filter :load_providers_and_banks, only: %w(list new create edit update)
  before_filter :load_bank_accounts, only: %w(select_bank_accounts create_bank_accounts)

  def index
    @fiduceo_retrievers = search(fiduceo_retriever_contains).order([sort_column,sort_direction]).page(params[:page]).per(params[:per_page])
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
      flash[:success] = 'Récupérateur paramétré.'
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
    FiduceoRetrieverService.destroy(@fiduceo_retriever)
    flash[:success] = 'Supprimé avec succès.'
    redirect_to account_fiduceo_retrievers_path
  end

  def fetch
    @fiduceo_retriever.schedule if @fiduceo_retriever.error?
    FiduceoDocumentFetcher.initiate_transactions(@fiduceo_retriever)
    flash[:success] = 'Traitement en cours...'
    redirect_to account_fiduceo_retrievers_path
  end

  def select_bank_accounts
  end

  def create_bank_accounts
    valid_bank_account_ids = @bank_accounts.map(&:id)
    bank_accounts = params[:bank_accounts].presence || []
    selected_bank_account_ids = bank_accounts.select { |k,v| k.in?(valid_bank_account_ids) && v == '1' }.map { |k,_| k }
    if selected_bank_account_ids.any?
      @fiduceo_retriever.schedule
      @bank_accounts.each do |bank_account|
        if bank_account.id.in? selected_bank_account_ids
          new_bank_account            = BankAccount.new
          new_bank_account.user       = @user
          new_bank_account.retriever  = @fiduceo_retriever
          new_bank_account.fiduceo_id = bank_account.id
          new_bank_account.bank_name  = @fiduceo_retriever.service_name
          new_bank_account.name       = bank_account.name
          new_bank_account.number     = bank_account.account_number
          new_bank_account.save
        end
      end
      emails = []
      collaborators = @user.groups.map(&:collaborators).flatten
      if collaborators.any?
        emails = collaborators.map(&:email)
      else
        emails = [@user.organization.leader.email]
      end
      emails.each do |email|
        NotificationMailer.delay(priority: 1).new_bank_accounts(@fiduceo_retriever, email)
      end
      flash[:success] = 'Les comptes bancaires sélectionnés ont été pris en compte.'
      redirect_to account_fiduceo_retrievers_path
    else
      flash[:error] = "Vous n'avez sélectionné aucun compte."
      render 'select_bank_accounts'
    end
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

  def verify_selection
    unless @fiduceo_retriever.wait_selection? && @fiduceo_retriever.bank? && action_name.in?(%w(select_bank_accounts create_bank_accounts))
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_fiduceo_retrievers_path
    end
  end

  def load_providers_and_banks
    fiduceo_provider = FiduceoProvider.new(@fiduceo_user_id)
    @providers = fiduceo_provider.providers
    @banks = fiduceo_provider.banks
  end

  def load_bank_accounts
    results = client.bank_accounts
    if client.response.code == 200
      @bank_accounts = results[1].select do |bank_account|
        bank_account.retriever_id == @fiduceo_retriever.fiduceo_id
      end
    else
      raise Fiduceo::Errors::ServiceUnavailable.new('bank_accounts')
    end
  end

  def client
    @client ||= Fiduceo::Client.new @user.fiduceo_id
  end
end
