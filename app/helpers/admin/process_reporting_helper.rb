# -*- encoding : UTF-8 -*-
module Admin::ProcessReportingHelper
  def sum_of_scanned_sheets(customers, time)
    periods = Scan::Period.where(
      :user_id.in   => customers.map(&:id),
      :start_at.lte => time,
      :end_at.gte   => time
    )
    periods = periods.where(duration: 1) if time.month % 3 != 0
    periods.entries.sum(&:scanned_sheets).to_i
  end

  def sum_of_bundled_pieces(organization, time)
    organization.temp_documents.bundled.where(
      :created_at.gte => time,
      :created_at.lte => time.end_of_month
    ).count
  end

  def sum_of_pre_assignments(organization, time)
    total = 0
    total += organization.expenses.where(
      :created_at.gte  => time,
      :created_at.lte  => time.end_of_month
    ).count
    total += organization.preseizures.where(
      :created_at.gte => time,
      :created_at.lte => time.end_of_month,
      :piece_id.nin   => [nil]
    ).count
    total
  end

  def sum_of_kits(customers, time)
    customer_ids = Scan::Period.where(
      :user_id.in     => customers.map(&:id),
      :created_at.gte => time,
      :created_at.lte => time.end_of_month
    ).select do |period|
      options = period.product_option_orders.select do |option|
        option.group_title == 'Envoi papier à iDocus pour numérisation' && option.title == 'Oui'
      end
      options.size > 0
    end.map(&:user_id).uniq

    previous_month = time - 1.month
    previous_count = Scan::Period.where(
      :user_id.in     => customer_ids,
      :created_at.gte => previous_month,
      :created_at.lte => previous_month.end_of_month
    ).select do |period|
      options = period.product_option_orders.select do |option|
        option.group_title == 'Envoi papier à iDocus pour numérisation' && option.title == 'Oui'
      end
      options.size > 0
    end.size

    customer_ids.size - previous_count
  end
end
