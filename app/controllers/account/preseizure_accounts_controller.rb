# -*- encoding : UTF-8 -*-
class Account::PreseizureAccountsController < Account::OrganizationController
  before_filter :account_params, only: :udpate

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
    raise ActiveRecord::RecordNotFound unless @account.preseizure.report.user.in? customers
    @account.update(account_params)

    respond_to do |format|
      format.json { render json: { status: :ok } }
    end
  end

private

  def account_params
    params.require(:account).permit(:number, :lettering, entries_attributes: [:id, :type, :amount])
  end
end
