# -*- encoding : UTF-8 -*-
class Admin::ReportingController < Admin::AdminController
  def index
    @year = params[:year].present? ? params[:year].to_i : Time.now.year
    @organizations = Organization.not_test.asc([:created_at, :name]).entries
    beginning_of_year = Time.local(@year)
    end_of_year = beginning_of_year.end_of_year
    @invoices = Invoice.any_in(organization_id: @organizations.map(&:_id)).
                        where(:created_at.gt => beginning_of_year + 1.month, :created_at.lt => end_of_year + 1.month).entries

    respond_to do |format|
      format.html
      format.xls do
        if params[:organization_id].present? && (organization = Organization.find(params[:organization_id]))
          customer_ids = organization.customers.map(&:id)
          filename = "reporting_#{organization.name.downcase.underscore}_#{@year}.xls"
        else
          customer_ids = @organizations.map{ |o| o.customers.map(&:id) }.flatten
          filename = "reporting_iDocus_#{@year}.xls"
        end
        periods = ::Scan::Period.where(
          :user_id.in   => customer_ids,
          :start_at.gte => beginning_of_year,
          :end_at.lte   => end_of_year
        ).asc(:start_at).entries
        data = PeriodsToXlsService.new(periods).execute
        send_data data, type: 'application/vnd.ms-excel', filename: filename
      end
    end
  end
end
