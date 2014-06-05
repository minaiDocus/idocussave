# -*- encoding : UTF-8 -*-
class Api::V1::OperationsController < ApiController
  before_filter :load_bank_account

  def index
    @operations = (@bank_account || user).operations.desc(:date)
    if params[:page].present? || params[:per_page].present?
      @operations = @operations.page(params[:page]).per(params[:per_page])
    end
    @operations = @operations.not_accessed if params[:not_accessed] == '1'
    @operations = @operations.entries
    if params[:not_accessed] == '1' && @operations.size > 0
      Operation.where(:_id.in => @operations.map(&:id)).update_all(accessed_at: Time.now)
    end
  end

private

  def load_bank_account
    @bank_account = user.bank_accounts.find(params[:bank_account_id]) if params[:bank_account_id].present?
  end
end
