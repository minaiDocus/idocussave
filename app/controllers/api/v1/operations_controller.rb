# -*- encoding : UTF-8 -*-
class Api::V1::OperationsController < ApiController
  before_filter :load_bank_account, only: :index

  # GET /api/v1/operations
  def index
    @operations = (@bank_account || user).operations.order(date: :desc)
    @operations = @operations.where("date <= ?", params[:end_date])    if params[:end_date]
    @operations = @operations.where("date >= ?", params[:start_date])  if params[:start_date]

    @operations = @operations.not_accessed if params[:not_accessed] == '1'

    if params[:page].present? || params[:per_page].present?
      @operations = @operations.page(params[:page]).per(params[:per_page])
    end

    if params[:not_accessed] == '1' && !@operations.empty?
      Operation.where(id: @operations.pluck(:id)).update_all(accessed_at: Time.now)
    end
  end


  # GET /api/v1/operations/import
  def import
    respond_to do |format|
      format.json do
        render json: { message: 'Not supported yet.' }.to_json
      end

      format.xml do
        file_path = begin
                      params[:file].tempfile.path
                    rescue
                      nil
                    end

        service = OperationImportService.new(file_path: file_path)

        service.execute

        render xml: OperationImportServicePresenter.new(service, view_context).message
      end
    end
  end

  private


  def load_bank_account
    @bank_account = user.bank_accounts.find(params[:bank_account_id]) if params[:bank_account_id].present?
  end
end
