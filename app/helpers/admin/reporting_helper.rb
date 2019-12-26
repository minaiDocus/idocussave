# frozen_string_literal: true

module Admin::ReportingHelper
  def invoice_at(time, organization, invoices)
    start_time = (time + 1.month).beginning_of_month

    end_time = start_time.end_of_month

    invoices.where('created_at > ? AND created_at < ? AND organization_id = ?', start_time, end_time, organization.id).first
  end

  def periods_at(date, organization, user_ids)
    periods = Period.includes(:billings).where('user_id IN (?) OR organization_id = ?', user_ids, organization.id).where('start_date <= ? AND end_date >= ?', date, date)

    [periods.where(is_centralized: true), periods.where(is_centralized: false)]
  end

  def get_options_months
    months = {
      'Janvier' => '01',
      'Fevrier' => '02',
      'Mars' => '03',
      'Avril' => '04',
      'Mai' => '05',
      'Juin' => '06',
      'Juillet' => '07',
      'Août' => '08',
      'Septembre' => '09',
      'Octobre' => '10',
      'Novembre' => '11',
      'Decembre' => '12'
    }
  end

  def get_options_years
    current_year = Date.today.strftime('%Y').to_i
    [*(current_year - 2)..current_year]
  end
end
