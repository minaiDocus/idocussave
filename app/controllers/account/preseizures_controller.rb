# -*- encoding : UTF-8 -*-
class Account::PreseizuresController < Account::OrganizationController
  before_filter :load_preseizure, except: :index

  def index
    if params[:pack_report_id].present?
      report = Pack::Report.preseizures.where(user_id: customer_ids, id: params[:pack_report_id]).first

      if report
        options = {}

        if params[:filter].present?
          options[:third_party] = params[:filter] unless report.name.match(/#{params[:filter]}/)
        end

        if params[:view] == 'delivered'
          options[:is_delivered] = AdvancedPreseizure::DELIVERY_STATE[:delivered]
        elsif params[:view] == 'not_delivered'
          options[:is_delivered] = AdvancedPreseizure::DELIVERY_STATE[:not_delivered]
        end

        if options.present?
          @preseizures = AdvancedPreseizure.search('preseizures', options, report)
        else
          @preseizures = report.preseizures
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
    CreatePreAssignmentDeliveryService.new(@preseizure, ['ibiza', 'exact_online']).execute
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
