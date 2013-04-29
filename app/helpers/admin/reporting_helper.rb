# -*- encoding : UTF-8 -*-
module Admin::ReportingHelper
  def invoice_at(time, organization, invoices)
    current_time = time + 1.month
    invoices.select do |invoice|
      invoice.number.match(/^#{current_time.strftime('%Y%m')}/) && invoice['organization_id'] == organization.id
    end.first
  end

  def periods_at(time, organization, user_ids)
    end_of_month = time.end_of_month
    periods = Scan::Period.any_of(
                                  { :user_id.in => user_ids },
                                  { organization_id: organization.id }
                                 ).
                           where(end_at: end_of_month).entries
    [
      periods.select { |e| e.is_centralized },
      periods.select { |e| !e.is_centralized }
    ]
  end
end