# -*- encoding : UTF-8 -*-
class Account::PackReportsController < Account::OrganizationController
  before_filter :load_report, except: :index

  def index
    @pack_reports = Pack::Report.preseizures.any_in(user_id: @user.customer_ids)
    @pack_reports = @pack_reports.where(name: /#{Regexp.quote(params[:name])}/) if params[:name].present?
    @pack_reports = @pack_reports.desc(:updated_at).limit(20).page(params[:page]).per(params[:per_page])
  end

  def show
    respond_to do |format|
      format.html {}
      format.csv do
        send_data(@report.to_csv(@report.user.csv_outputter!), type: "text/csv", filename: "#{@report.name.gsub(' ','_')}.csv")
      end
    end
  end

  def deliver
    if @user.organization.ibiza && @user.organization.ibiza.is_configured? && !@report.is_locked
      @report.update_attribute(:is_locked, true)
      preseizures = @report.preseizures.by_position.not_locked.not_delivered.entries
      ids = preseizures.map(&:id)
      Pack::Report::Preseizure.where(:_id.in => ids).update_all(is_locked: true)
      @user.organization.ibiza.
        delay(queue: 'ibiza export', priority: 2).
        export(preseizures)
    end
    respond_to do |format|
      format.json { render json: { status: :ok } }
    end
  end

private

  def load_report
    @report = Pack::Report.find params[:id]
    unless current_user.is_admin || @user.my_organization == @report.organization || @user.customers.include?(@report.user)
      raise Mongoid::Errors::DocumentNotFound.new(Pack::Report, params[:id])
    end
  end
end
