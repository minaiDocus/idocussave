# -*- encoding : UTF-8 -*-
class Account::ReportingController < Account::AccountController
  def show
    @year = !params[:year].blank? ? params[:year].to_i : Time.now.year

    if @user.is_prescriber && @user.organization
      @users = @user.customers.asc(:code)
    else
      @users = [@user]
    end
    @periods = Period.where(
      :user_id.in   => @users.map(&:id),
      :start_at.gte => Time.local(@year),
      :end_at.lte   => Time.local(@year).end_of_year
    ).asc(:start_at).entries

    respond_to do |format|
      format.html
      format.xls do
        data = PeriodsToXlsService.new(@periods).execute
        send_data data, type: 'application/vnd.ms-excel', filename: "reporting_iDocus_#{@year}.xls"
      end
    end
  end
end
