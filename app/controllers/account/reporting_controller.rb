# frozen_string_literal: true

class Account::ReportingController < Account::AccountController
  def show
    if Collaborator.new(@user).has_many_organization? && !params[:organization_id].present?
      redirect_to account_reporting_path(organization_id: @user.organizations.first.id)
    else
      @year = begin
                Integer(params[:year])
              rescue StandardError
                Time.now.year
              end

      date = Date.parse("#{@year}-01-01")
      periods = Period.includes(:billings, :user, :subscription).where(user_id: account_ids)
                      .where('start_date >= ? AND end_date <= ?', date, date.end_of_year)
                      .order(start_date: :asc)
      @periods_by_users = periods.group_by { |period| period.user.id }.each do |_user, periods|
        periods.sort_by!(&:start_date)
      end

      respond_to do |format|
        format.html
        format.xls do
          data = Subscription::PeriodsToXls.new(periods).execute
          send_data data, type: 'application/vnd.ms-excel', filename: "reporting_iDocus_#{@year}.xls"
        end
      end
    end
  end
end
