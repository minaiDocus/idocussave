# -*- encoding : UTF-8 -*-
class Account::Report::ExpensesController < Account::AccountController
  layout nil

  before_filter :load_report, :verify_rights

  private

  def load_report
    @report = Pack::Report.find params[:id]
  end

  def verify_rights
    if @report.user != current_user and !current_user.in?(@report.user.try(:prescribers) || []) and !current_user.is_admin
      redirect_to root_path
    end
  end

  public

  def show
    basename = @report.name.gsub(' ','_')
    respond_to do |format|
      format.html {}
      format.xlsx do
        send_data(@report.expenses.render_xlsx, filename: "#{basename}.xlsx")
      end
      format.pdf do
        send_data(@report.expenses.render_pdf, filename: "#{basename}.pdf")
      end
    end
  end
end
