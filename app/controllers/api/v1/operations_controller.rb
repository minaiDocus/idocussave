# -*- encoding : UTF-8 -*-
class Api::V1::OperationsController < ApiController
  before_filter :load_bank_account, only: :index

  def index
    @operations = (@bank_account || user).operations.desc(:date)
    @operations = @operations.where(:date.gte => params[:start_date]) if params[:start_date]
    @operations = @operations.where(:date.lte => params[:end_date])   if params[:end_date]
    if params[:page].present? || params[:per_page].present?
      @operations = @operations.page(params[:page]).per(params[:per_page])
    end
    @operations = @operations.not_accessed if params[:not_accessed] == '1'
    @operations = @operations.entries
    if params[:not_accessed] == '1' && @operations.size > 0
      Operation.where(:_id.in => @operations.map(&:id)).update_all(accessed_at: Time.now)
    end
  end

  def import
    respond_to do |format|
      format.json {
        render json: { message: 'Not supported yet.' }.to_json
      }
      format.xml {
        file_path = params[:file].tempfile.path rescue nil
        service = OperationImportService.new(file_path: file_path)
        service.execute
        render xml: OperationImportServicePresenter.new(service, view_context).message
      }
    end
  end

private

  def load_bank_account
    @bank_account = user.bank_accounts.find(params[:bank_account_id]) if params[:bank_account_id].present?
  end
end
