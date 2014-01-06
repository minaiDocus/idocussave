# -*- encoding : UTF-8 -*-
class Account::PreseizuresController < Account::OrganizationController
  before_filter :preseizure_params, only: :update
  before_filter :load_preseizure, except: :index

  def index
    report = @user.packs.where(:name => /#{params[:name].gsub('_',' ')}/).first.try(:report)
    report = @user.organization.reports.where(:name => /#{params[:name].gsub('_',' ')}/).first unless report
    if report
      @preseizures = report.preseizures.by_position.page(params[:page]).per(params[:per_page])
    else
      @preseizures = []
    end
  end

  def update
    @preseizure.update_attributes(preseizure_params)
    respond_to do |format|
      format.json { render json: { status: :ok } }
    end
  end

  def deliver
    if @user.organization.ibiza && @user.organization.ibiza.is_configured? && !@preseizure.is_delivered
      @user.organization.ibiza.
        delay(queue: 'ibiza export', priority: 2).
        export([@preseizure])
    end
    respond_to do |format|
      format.json { render json: { status: :ok } }
    end
  end

private

  def load_preseizure
    @preseizure = Pack::Report::Preseizure.find params[:id]
    raise Mongoid::Errors::DocumentNotFound.new(Pack::Report::Preseizure, params[:id]) unless @preseizure.report.user.in? @user.customers
  end

  def preseizure_params
    params.require(:preseizure).permit(:position,
                                       :date,
                                       :third_party,
                                       :piece_number,
                                       :amount,
                                       :currency,
                                       :convertion_rate,
                                       :deadline_date,
                                       :observation)
  end
end