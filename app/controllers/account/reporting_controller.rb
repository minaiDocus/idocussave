# -*- encoding : UTF-8 -*-
class Account::ReportingController < Account::AccountController
  def show
    @year = Integer(params[:year]) rescue Time.now.year
    @users = if @user.is_prescriber && @user.organization
      @user.customers.order(code: :asc)
    else
      [@user]
    end

    date = Date.parse("#{@year}-01-01")
    periods = Period.where(user_id: @users.map(&:id)).
      where('start_date >= ? AND end_date <= ?', date, date.end_of_year).
      order(start_date: :asc)
    @periods_by_users = periods.group_by { |period| period.user.id }.each do |user, periods|
      periods.sort_by!(&:start_date)
    end

    respond_to do |format|
      format.html
      format.xls do
        data = PeriodsToXlsService.new(periods).execute
        send_data data, type: 'application/vnd.ms-excel', filename: "reporting_iDocus_#{@year}.xls"
      end
    end
  end
end
