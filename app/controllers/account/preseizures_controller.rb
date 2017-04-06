# -*- encoding : UTF-8 -*-
class Account::PreseizuresController < Account::OrganizationController
  before_filter :load_preseizure, except: :index

  def index
    if params[:pack_report_id].present?
      report = Pack::Report.preseizures.where(user_id: customer_ids, id: params[:pack_report_id]).first

      if report
        @preseizures = report.preseizures
        if params[:view] == 'delivered'
          @preseizures = @preseizures.where(is_delivered: true)
        elsif params[:view] == 'not_delivered'
          @preseizures = @preseizures.where(is_delivered: false)
        end
        @preseizures = @preseizures.by_position.page(params[:page]).per(params[:per_page])
      else
        @preseizures = []
      end
    else
      redirect_to root_path
    end
  end

  def update
    respond_to do |format|
      begin
        @preseizure.update(preseizure_params)
        format.json { render json: { status: :ok } }
      end
    end
  end

  def deliver
    CreatePreAssignmentDeliveryService.new(@preseizure).execute
    respond_to do |format|
      format.json { render json: { status: :ok } }
    end
  end

private

  def load_preseizure
    @preseizure = Pack::Report::Preseizure.find params[:id]
    raise ActiveRecord::RecordNotFound unless @preseizure.report.user.in? customers
  end

  def preseizure_params
    params.require(:preseizure).permit(:position,
                                       :date,
                                       :third_party,
                                       :operation_label,
                                       :piece_number,
                                       :amount,
                                       :currency,
                                       :conversion_rate,
                                       :deadline_date,
                                       :observation)
  end
end
