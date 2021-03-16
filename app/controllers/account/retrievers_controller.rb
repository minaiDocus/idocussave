# frozen_string_literal: true

class Account::RetrieversController < Account::RetrieverController
  before_action :verif_account, except: %w[index edit export_connector_to_xls get_connector_xls new_internal]
  before_action :load_budgea_config, except: %w[export_connector_to_xls get_connector_xls]
  before_action :load_retriever, except: %w[index list new export_connector_to_xls get_connector_xls new_internal create]
  before_action :verify_retriever_state, except: %w[index list new export_connector_to_xls get_connector_xls new_internal edit_internal create]
  before_action :load_retriever_edition, only: %w[new edit]

  def index
    retrievers = if @account
                   @account.retrievers
                 else
                   Retriever.where(user: accounts)
                 end
    @retrievers = Retriever.search_for_collection(retrievers, search_terms(params[:retriever_contains]))
                           .joins(:user)
                           .order("#{sort_column} #{sort_direction}")
                           .page(params[:page])
                           .per(params[:per_page])
    @is_filter_empty = search_terms(params[:retriever_contains]).empty?
    if params[:part].present?
      render partial: 'retrievers', locals: { scope: :account }
    end
  end

  def list; end

  def new
    if params[:create] == '1'
      flash[:success] = 'Edition terminée'
      redirect_to account_retrievers_path
    end
  end

  def new_internal
    @retriever = Retriever.new
    @connectors = Connector.idocus
  end

  def create
    @retriever = Retriever.new(retriever_params)

    @retriever.user = @account
    @retriever.service_name = @retriever.connector.name
    @retriever.capabilities = @retriever.connector.capabilities

    if @retriever.save
      redirect_to account_retrievers_path
    else
      render 'new_internal'
    end
  end

  def edit; end

  def edit_internal
    @retriever = Retriever.find(params[:id])
  end

  def update
    @retriever = Retriever.find(params[:id])

    if @retriever.update(retriever_params)
      redirect_to account_retrievers_path
    else
      render 'edit_internal'
    end
  end

  def export_connector_to_xls
    array_document = params[:documents].to_s.split(/\;/)
    array_bank     = params[:banks].to_s.split(/\;/)
    file           = nil

    CustomUtils.mktmpdir('retrievers_controller', '/nfs/tmp', false) do |dir|
      file           = OpenStruct.new({path: "#{dir}/list_des_automates.xls", close: nil})
      xls_data       = []

      max_length     = array_document.size > array_bank.size ? array_document.size : array_bank.size

      tmp_data       = {}
      tmp_data[:documents] = "Documents"
      tmp_data[:banques]   = "Banques"
      xls_data << OpenStruct.new(tmp_data)

      max_length.times do |i|
        tmp_data = {}
        tmp_data[:documents] = array_document[i] if array_document[i].present?
        tmp_data[:banques]   = array_bank[i]     if array_bank[i].present?
        next if !array_document[i].present? && !array_bank[i].present?
        xls_data << OpenStruct.new(tmp_data)
      end

      ToXls::Writer.new(xls_data, columns: [:documents, :banques], headers: false).write_io(file.path)

      FileUtils.delay_for(5.minutes, queue: :low).remove_entry(dir, true)
    end

    render json: { key: Base64.encode64(file.path.to_s), status: :ok }
  end

  def get_connector_xls
    file_path = Base64.decode64(params[:key])

    send_data File.read(file_path), filename: 'liste_automates.xls'
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

  def load_retriever
    if @account
      @retriever = @account.retrievers.find params[:id]
    else
      @retriever = Retriever.find params[:id]
      @account = @retriever.user
      session[:retrievers_account_id] = @account.id
    end
  end

  def verify_retriever_state
    is_ok = false

    if action_name.in? %w[edit update]
      if @retriever.ready? || @retriever.error? || @retriever.waiting_additionnal_info?
        is_ok = true
      end
    end

    unless is_ok
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_retrievers_path
    end
  end

  def load_retriever_edition
    @user_token = @account.get_authentication_token
    @bi_token = @account.try(:budgea_account).try(:access_token)
    @journals = @account.account_book_types.map do |journal|
      "#{journal.id}:#{journal.name}"
    end.join('_')
    @contact_company = @account.company
    @contact_name = @account.last_name
    @contact_first_name = @account.first_name
  end

  def pattern_index
    return '[0-9]' if params[:index] == 'number'

    params[:index].to_s
  end

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

  def retriever_params
    params.require(:retriever).permit(:connector_id, :user_id, :journal_id, :login, :password, :name, :connector_id)
  end
end
