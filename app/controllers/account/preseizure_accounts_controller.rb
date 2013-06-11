# -*- encoding : UTF-8 -*-
class Account::PreseizureAccountsController < Account::OrganizationController
  before_filter :account_params, only: :udpate

  def index
    if params[:name]
      pack = @user.packs.where(:name => /#{params[:name].gsub('_',' ')}/).first
      if pack && pack.report
        if params[:position].presence && params[:position].match(/\d+/)
          position = params[:position].to_i
        else
          position = 1
        end
        preseizure = pack.report.preseizures.where(position: position).first
        @preseizure_accounts = preseizure.accounts.by_position
      else
        @preseizure_accounts = []
      end
    else
      @preseizure_accounts = []
    end
  end

  def update
    @account = Pack::Report::Preseizure::Account.find params[:id]
    raise Mongoid::Errors::DocumentNotFound.new(Pack::Report::Preseizure::Account, params[:id]) unless @user.packs.include? @account.preseizure.report.pack
    @account.update_attributes(account_params)
    respond_to do |format|
      format.json { render json: { status: :ok } }
    end
  end

private

  def account_params
    params.require(:account).permit(:number, :lettering, entries_attributes: [:id, :type, :amount])
  end
end