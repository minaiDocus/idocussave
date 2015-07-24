# -*- encoding : UTF-8 -*-
class Account::Report::PreseizuresController < Account::AccountController
  layout false

  before_filter :load_report, :verify_rights

  private

  def load_report
    @report = Pack::Report.find params[:id]
  end

  def verify_rights
    if @report.user == current_user || !current_user.in?(@report.user.try(:prescribers) || []) and !current_user.is_admin
      redirect_to root_path
    end
  end

  public

  def show
    respond_to do |format|
      format.html {}
      format.csv do
        data = PreseizuresToCsv.new(@report.user, @report.preseizures).execute
        send_data(data, type: "text/csv", filename: "#{@report.name.gsub(' ','_')}.csv")
      end
    end
  end
end
