# -*- encoding : UTF-8 -*-
class Account::PackReportsController < Account::OrganizationController
  before_filter :load_report, except: :index

  def index
    @pack_reports = Pack::Report.preseizures.any_in(user_id: @user.customer_ids)
    if params[:name]
      pack_ids = @user.packs.where(name: /#{params[:name]}/).distinct(:_id)
      @pack_reports = @pack_reports.any_in(pack_id: pack_ids)
    end
    @pack_reports = @pack_reports.desc(:created_at).limit(20).page(params[:page]).per(params[:per_page])
  end

  def show
    respond_to do |format|
      format.html {}
      format.csv do
        send_data(@report.to_csv(@report.pack.owner.csv_outputter!), type: "text/csv", filename: "#{@report.pack.name.gsub(' ','_').sub('_all','')}.csv")
      end
    end
  end

  def deliver
    if @user.organization.ibiza && @user.organization.ibiza.is_configured?
      @user.organization.ibiza.export(@report.preseizures)
    end
    respond_to do |format|
      format.json { render json: { status: :ok } }
    end
  end

private

  def load_report
    @report = Pack::Report.find params[:id]
    pack_ids = @user.packs.distinct(:_id)
    raise Mongoid::Errors::DocumentNotFound.new(Pack::Report, params[:id]) unless @report.pack.id.in?(pack_ids)
  end
end