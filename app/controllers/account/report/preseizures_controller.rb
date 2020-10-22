# frozen_string_literal: true

class Account::Report::PreseizuresController < Account::AccountController
  layout false

  before_action :load_report, :verify_rights

  private

  def load_report
    @report = Pack::Report.find params[:id]
  end

  def verify_rights
    redirect_to root_path unless @report.user.in?(accounts)
  end

  public

  # FIXME : check if needed
  def show
    respond_to do |format|
      format.html {}
      format.csv do
        data = PreseizureExport::PreseizuresToCsv.new(@report.user, @report.preseizures).execute
        send_data(data, type: 'text/csv', filename: "#{@report.name.tr(' ', '_')}.csv")
      end
    end
  end
end
