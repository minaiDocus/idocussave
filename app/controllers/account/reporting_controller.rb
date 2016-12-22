# -*- encoding : UTF-8 -*-
class Account::ReportingController < Account::AccountController
  # GET /account/reporting
  def show
    @year = !params[:year].blank? ? params[:year].to_i : Time.now.year

    @users = if @user.is_prescriber && @user.organization
               @user.customers.order(code: :asc)
             else
               [@user]
             end

    @periods = Period.where(user_id: @users.map(&:id)).where('start_at >= ? AND end_at <= ?', Time.local(@year), Time.local(@year).end_of_year).order(start_at: :asc)

    respond_to do |format|
      format.html

      format.xls do
        data = PeriodsToXlsService.new(@periods).execute

        send_data data, type: 'application/vnd.ms-excel', filename: "reporting_iDocus_#{@year}.xls"
      end
    end
  end
end
