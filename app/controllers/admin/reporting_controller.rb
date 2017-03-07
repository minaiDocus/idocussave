# -*- encoding : UTF-8 -*-
class Admin::ReportingController < Admin::AdminController
  # GET /index/reporting
  def index
    @year = params[:year].present? ? params[:year].to_i : Time.now.year

    beginning_of_year = Time.local(@year)

    end_of_year = beginning_of_year.end_of_year

    @organizations = Organization.billed_for_year(@year).order(name: :asc)

    @invoices = Invoice.where(organization_id: @organizations.map(&:id)).where("created_at > ? AND created_at < ?", beginning_of_year + 1.month, end_of_year + 1.month)

    respond_to do |format|
      format.html
      format.xls do
        if params[:simplified] == '1'
          filename = "reporting_simplifié_iDocus_#{@year}.xls"

          send_data GlobalReportToXls.new(@year).execute, type: 'application/vnd.ms-excel', filename: filename
        else
          if params[:organization_id].present? && (organization = Organization.find(params[:organization_id]))
            organization_ids = [organization.id]

            customer_ids = organization.customers.pluck(:id)

            filename = "reporting_#{organization.name.downcase.underscore}_#{@year}.xls"

            with_organization_info = false
          else
            organization_ids = @organizations.pluck(:id)

            customer_ids = @organizations.map { |o| o.customers.pluck(:id) }.flatten

            filename = "reporting_iDocus_#{@year}.xls"

            with_organization_info = true
          end

          # NOTE temporary fix using +1.hour
          periods = Period.where("user_id IN (?) OR organization_id IN (?)", customer_ids, organization_ids).where("start_at  >= ? AND end_at <= ?", beginning_of_year, end_of_year + 1.hour).order(start_at: :asc)

          data = PeriodsToXlsService.new(periods, with_organization_info).execute

          send_data data, type: 'application/vnd.ms-excel', filename: filename
        end
      end
    end
  end
end
