# -*- encoding : UTF-8 -*-
module Admin::ReportingHelper
  def invoice_at(time, organization, invoices)
    start_time = (time + 1.month).beginning_of_month

    end_time = start_time.end_of_month

    invoices.where("created_at > ? AND created_at < ? AND organization_id = ?", start_time, end_time, organization.id).first
  end

  def periods_at(time, organization, user_ids)
    periods = Period.where('user_id IN (?) OR organization_id = ?', user_ids, organization.id).where("start_at <= ? AND end_at >= ?", time.dup, time.dup)

    [periods.where(is_centralized: true), periods.where(is_centralized: false)]
  end
end
