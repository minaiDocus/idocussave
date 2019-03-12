# -*- encoding : UTF-8 -*-
class Account::RetrieversController < Account::RetrieverController
  before_action :load_budgea_config
  before_action :load_retriever, except: %w(index list new)
  before_action :verify_retriever_state, except: %w(index list new)
  before_action :load_retriever_edition, only: %w(new edit)


  def index
    if @account
      retrievers = @account.retrievers
    else
      retrievers = Retriever.where(user: accounts)
    end

    @retrievers = Retriever.search_for_collection(retrievers, search_terms(params[:retriever_contains]))
                  .joins(:user)
                  .order("#{sort_column} #{sort_direction}")
                  .page(params[:page])
                  .per(params[:per_page])
    @is_filter_empty = search_terms(params[:retriever_contains]).empty?
    render partial: 'retrievers', locals: { scope: :account } if params[:part].present?
  end

  def list
  end

  def new
    if params[:create] == '1'
      flash[:success] = 'Edition terminée'
      redirect_to account_retrievers_path
    end
  end

  def edit
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

    if action_name.in? %w(edit update)
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
    @account.update_authentication_token unless @account.authentication_token.present?
    @user_token = @account.authentication_token
    @bi_token = @account.try(:budgea_account).try(:access_token)
    @journals = @account.account_book_types.map do |journal|
      "#{journal.id}:#{journal.name}"
    end.join("_")
    @contact_company    = @account.company
    @contact_name       = @account.last_name
    @contact_first_name = @account.first_name
  end

  def pattern_index
    return '[0-9]' if params[:index] == 'number'
    params[:index].to_s
  end

  def load_budgea_config
    bi_config = {
                  url:    "https://#{Budgea.config.domain}/2.0",
                  c_id:   Budgea.config.client_id,
                  c_ps:   Budgea.config.client_secret,
                  c_ky:   Budgea.config.encryption_key ? Base64.encode64(Budgea.config.encryption_key.to_json.to_s) : '',
                  proxy:  Budgea.config.proxy
                }.to_json
    @bi_config = Base64.encode64(bi_config.to_s)
  end
end
