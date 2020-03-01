# frozen_string_literal: true

class Account::Report::ExpensesController < Account::AccountController
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
    basename = @report.name.tr(' ', '_')
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
