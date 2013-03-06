# -*- encoding : UTF-8 -*-
class Account::Report::PreseizuresController < Account::AccountController
  layout nil

  before_filter :load_report, :verify_rights

  private

  def load_report
    @report = Pack::Report.find params[:id]
  end

  def verify_rights
    if @report.pack.owner == current_user || @report.pack.owner.try(:prescriber) != current_user and !current_user.is_admin
      redirect_to root_path
    end
  end

  public

  def show
    respond_to do |format|
      format.html {}
      format.csv do
        send_data(@report.to_csv(@report.pack.owner.csv_outputter!), type: "text/csv", filename: "#{@report.pack.name.gsub(' ','_').sub('_all','')}.csv")
      end
    end
  end
end
