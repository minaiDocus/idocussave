# frozen_string_literal: true

class Account::Organization::RetrieversController < Account::Organization::RetrieverController
  before_action :redirect_to_new_page
  before_action :load_retriever, except: %w[index list new create]
  before_action :verify_rights, except: %w[index list new create]
  before_action :load_connectors, only: %w[list new create edit update]

  def index
    @retrievers = Retriever.search_for_collection(@customer.retrievers, search_terms(params[:fiduceo_retriever_contains])).order(sort_column => sort_direction).page(params[:page]).per(params[:per_page])
    if params[:part].present?
      render partial: 'account/retrievers/retrievers', locals: { scope: :collaborator }
    end
  end

  def list; end

  def new
    @retriever = Retriever.new
    @retriever.connector_id = params[:connector_id]
  end

  def create
    @retriever = Retriever.new(retriever_params)
    @retriever.confirm_dyn_params = true
    @retriever.check_journal      = true
    @retriever.user = @customer
    if @retriever.save
      flash[:success] = 'Création en cours.'
      redirect_to account_organization_customer_retrievers_path(@organization, @customer)
    else
      render :new
    end
  end

  def edit; end

  def update
    if Retriever::Update.new(@retriever, retriever_params).execute
      flash[:success] = if @retriever.configuring?
                          'Configuration en cours.'
                        else
                          'Modifié avec succès.'
                        end
      redirect_to account_organization_customer_retrievers_path(@organization, @customer)
    else
      render :edit
    end
  end

  def waiting_additionnal_info; end

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
      { param1: %i[name value] },
      { param2: %i[name value] },
      { param3: %i[name value] },
      { param4: %i[name value] },
      { check_journal: true }
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

    if action_name.in? %w[edit update destroy run]
      if action_name == 'destroy' && (@retriever.ready? || @retriever.error? || @retriever.unavailable?)
        is_ok = true
      elsif @retriever.ready? || @retriever.error?
        is_ok = true unless action_name == 'run' && @retriever.budgea_id.nil?
      end
    elsif action_name.in?(%w[waiting_additionnal_info additionnal_info]) && @retriever.waiting_additionnal_info?
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

  def redirect_to_new_page
    redirect_to account_retrievers_path(account_id: @customer.id)
  end
end
