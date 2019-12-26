# frozen_string_literal: true

class Admin::ReportingController < Admin::AdminController
  def index
    @year = begin
              Integer(params[:year])
            rescue StandardError
              Time.now.year
            end
    date = Date.parse("#{@year}-01-01")
    @organizations = Organization.billed_for_year(@year).order(name: :asc)
    @invoices = Invoice.where(organization_id: @organizations.map(&:id))
                       .where(created_at: date.end_of_month..(date.end_of_month + 12.month))

    respond_to do |format|
      format.html
      format.xls do
        Timeout.timeout 300 do
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

            periods = Period.includes(:billings).where('user_id IN (?) OR organization_id IN (?)', customer_ids, organization_ids)
                            .where('start_date >= ? AND end_date <= ?', date, date.end_of_year)
                            .order(start_date: :asc)

            data = PeriodsToXlsService.new(periods, with_organization_info).execute
            send_data data, type: 'application/vnd.ms-excel', filename: filename
          end
        end
      rescue Timeout::Error
        puts 'Request too long'
        raise 'Request too long'
      end
    end
  end
end
