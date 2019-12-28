# frozen_string_literal: true

class Account::PreseizureAccountsController < Account::OrganizationController
  before_action :account_params, only: :udpate
  skip_before_action :load_organization, only: :accounts_list

  def index
    if params[:pack_report_id].present?
      report = Pack::Report.preseizures.where(user_id: customer_ids, id: params[:pack_report_id]).first

      if report
        preseizure = report.preseizures.find params[:preseizure_id]

        @preseizure_accounts = preseizure.accounts.order(type: :asc).includes(:entries).to_a
      else
        @preseizure_accounts = []
      end
    else
      @preseizure_accounts = []
    end
  end

  def update
    @account = Pack::Report::Preseizure::Account.find params[:id]
    unless @account.preseizure.report.user.in? customers
      raise ActiveRecord::RecordNotFound
    end

    @account.update(account_params)

    respond_to do |format|
      format.json { render json: { status: :ok } }
    end
  end

  def accounts_list
    account        = Pack::Report::Preseizure::Account.find params[:account_id]
    @accounts_name = account.get_similar_accounts

    render partial: 'account/preseizure_accounts/accounts_list'
  end

  private

  def account_params
    params.require(:account).permit(:number, :lettering, entries_attributes: %i[id type amount])
  end
end
