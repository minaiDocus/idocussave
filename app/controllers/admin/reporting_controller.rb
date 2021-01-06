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

    @total = 12.times.map { |e| [0,0,0] }

    respond_to do |format|
      format.html
      format.xls do
        Timeout.timeout 600 do
          if params[:simplified] == '1'
            filename = "reporting_simplifié_iDocus_#{@year}.xls"
            send_data Report::GlobalToXls.new(@year).execute, type: 'application/vnd.ms-excel', filename: filename
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

            data = Subscription::PeriodsToXls.new(periods, with_organization_info).execute
            send_data data, type: 'application/vnd.ms-excel', filename: filename
          end
        end
      rescue Timeout::Error
        puts 'Request too long'
        raise 'Request too long'
      end
    end
  end

  def row_organization
    @year = begin
              Integer(params[:year])
            rescue StandardError
              Time.now.year
            end
    date = Date.parse("#{@year}-01-01")


    @organization = Organization.find(params[:organization_id])

    @invoices = Invoice.where(organization_id: params[:organization_id]).invoice_at(date)

    render partial: 'row_organization'
  end

  def total_footer
    @year = begin
              Integer(params[:year])
            rescue StandardError
              Time.now.year
            end

    @total = params[:total].transpose

    render partial: 'total_footer'
  end
end
