# -*- encoding : UTF-8 -*-
class Account::Organization::RetrieversController < Account::Organization::RetrieverController
  before_filter :load_retriever, except: %w(index list new create)
  before_filter :verify_rights, except: %w(index list new create)
  before_filter :load_connectors, only: %w(list new create edit update)

  def index
    @retrievers = Retriever.search_for_collection(@customer.retrievers, search_terms(params[:fiduceo_retriever_contains])).order(sort_column => sort_direction).page(params[:page]).per(params[:per_page])
    render partial: 'account/retrievers/retrievers', locals: { scope: :collaborator } if params[:part].present?
  end

  def list
  end

  def new
    @retriever = Retriever.new
    @retriever.connector_id = params[:connector_id]
  end

  def create
    @retriever = Retriever.new(retriever_params)
    @retriever.confirm_dyn_params = true
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
    if UpdateRetriever.new(@retriever, retriever_params).execute
      if @retriever.configuring?
        flash[:success] = 'Configuration en cours.'
      else
        flash[:success] = 'Modifié avec succès.'
      end
      redirect_to account_organization_customer_retrievers_path(@organization, @customer)
    else
      render :edit
    end
  end

  def destroy
    if @retriever.unavailable?
      @retriever.bank_accounts.destroy_all
      @retriever.destroy
      flash[:success] = 'Supprimé avec succès.'
    else
      if @retriever.destroy_connection
        flash[:success] = 'Suppression en cours.'
      else
        flash[:error] = 'Impossible de supprimer.'
      end
    end
    redirect_to account_organization_customer_retrievers_path(@organization, @customer)
  end

  def run
    @retriever.run
    flash[:success] = 'Traitement en cours...'
    redirect_to account_organization_customer_retrievers_path(@organization, @customer)
  end

  def waiting_additionnal_info
  end

  def additionnal_info
    if @retriever.update(answers: params[:answers])
      @retriever.configure_connection
      flash[:info] = 'Traitement en cours...'
      redirect_to account_organization_customer_retrievers_path(@organization, @customer)
    else
      render :waiting_additionnal_info
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

  def retriever_params
    dyn_attrs = [
      { param1: [:name, :value] },
      { param2: [:name, :value] },
      { param3: [:name, :value] },
      { param4: [:name, :value] },
    ]
    if action_name == 'update'
      params.require(:retriever).permit(:journal_id, :name, *dyn_attrs)
    else
      params.require(:retriever).permit(:connector_id, :journal_id, :name, *dyn_attrs)
    end
  end

  def load_retriever
    @retriever = @customer.retrievers.find params[:id]
  end

  def verify_rights
    is_ok = false

    if action_name.in? %w(edit update destroy run)
      if action_name == 'destroy' && (@retriever.ready? || @retriever.error? || @retriever.unavailable?)
        is_ok = true
      elsif @retriever.ready? || @retriever.error?
        is_ok = true unless action_name == 'run' && @retriever.budgea_id.nil?
      end
    elsif action_name.in?(%w(waiting_additionnal_info additionnal_info)) && @retriever.waiting_additionnal_info?
      is_ok = true
    end

    unless is_ok
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_retrievers_path
    end
  end

  def load_connectors
    @connectors = Connector.budgea.order(name: :asc).list
    @providers  = Connector.budgea.providers.order(name: :asc)
    @banks      = Connector.budgea.banks.order(name: :asc)
  end
end
