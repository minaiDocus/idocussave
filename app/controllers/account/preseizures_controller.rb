# frozen_string_literal: true

class Account::PreseizuresController < Account::OrganizationController
  before_action :load_preseizure, except: :index

  def index
    if params[:pack_report_id].present?
      report = Pack::Report.preseizures.where(user_id: customer_ids, id: params[:pack_report_id]).first

      if report
        @preseizures = report.preseizures

        if params[:filter].present?
          unless Pack::Report.preseizures.where(id: params[:pack_report_id]).where('pack_reports.name LIKE ?', "%#{params[:filter].gsub('+', ' ')}%").count > 0
            @preseizures = @preseizures.where('third_party LIKE ?', "%#{params[:filter].gsub('+', ' ')}%")
          end
        end

        if params[:view] == 'delivered'
          @preseizures = @preseizures.delivered
        elsif params[:view] == 'not_delivered'
          @preseizures = @preseizures.not_delivered
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
      @preseizure.assign_attributes(preseizure_params)
      if @preseizure.conversion_rate_changed? || @preseizure.amount_changed?
        @preseizure.update_entries_amount
      end
      @preseizure.save

      format.json { render json: { status: :ok } }
    end
  end

  def deliver
    PreAssignment::CreateDelivery.new(@preseizure, %w[ibiza exact_online my_unisoft]).execute

    respond_to do |format|
      format.json { render json: { status: :ok } }
    end
  end

  private

  def load_preseizure
    @preseizure = Pack::Report::Preseizure.find params[:id]
    unless @preseizure.report.user.in? customers
      raise ActiveRecord::RecordNotFound
    end
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
