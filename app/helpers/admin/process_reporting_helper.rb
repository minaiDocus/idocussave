# -*- encoding : UTF-8 -*-
module Admin::ProcessReportingHelper
  def sum_of_scanned_sheets(organization, time)
    organization.temp_documents.scan.where(
      :created_at.gte => time,
      :created_at.lte => time.end_of_month
    ).any_of(
      { state: 'processed', is_an_original: true },
      { state: 'bundled' }
    ).size
  end

  def sum_of_bundled(organization, time)
    total = organization.temp_documents.bundled.where(
      :created_at.gte => time,
      :created_at.lte => time.end_of_month,
      delivery_type: 'scan'
    ).count
    total += organization.temp_documents.bundled.where(
      :created_at.gte => time,
      :created_at.lte => time.end_of_month,
      :delivery_type.in => ['upload', 'dematbox_scan']
    ).sum(:pages_number).to_i || 0
    total
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

  def sum_of_requested_kits(customers, time)
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

  def sum_of_sent_kits(organization, time)
    organization.paper_processes.kits.where(
      :created_at.gte  => time,
      :created_at.lte  => time.end_of_month
    ).size
  end

  def sum_of_receipts(organization, time)
    organization.paper_processes.receipts.where(
      :created_at.gte  => time,
      :created_at.lte  => time.end_of_month
    ).size
  end

  def sum_of_paperclips(customers, time)
    periods = Scan::Period.where(
      :user_id.in     => customers.map(&:id),
      :created_at.gte => time,
      :created_at.lte => time.end_of_month
    )
    periods = periods.where(duration: 1) if time.month % 3 != 0
    periods.sum(:paperclips).to_i
  end

  def sum_of_oversized(customers, time)
    periods = Scan::Period.where(
      :user_id.in     => customers.map(&:id),
      :created_at.gte => time,
      :created_at.lte => time.end_of_month
    )
    periods = periods.where(duration: 1) if time.month % 3 != 0
    periods.sum(:oversized).to_i
  end

  def sum_of_returns_500(organization, time)
    organization.paper_processes.returns.l500.where(
      :created_at.gte  => time,
      :created_at.lte  => time.end_of_month
    ).size
  end

  def sum_of_returns_1000(organization, time)
    organization.paper_processes.returns.l1000.where(
      :created_at.gte  => time,
      :created_at.lte  => time.end_of_month
    ).size
  end

  def sum_of_returns_3000(organization, time)
    organization.paper_processes.returns.l3000.where(
      :created_at.gte  => time,
      :created_at.lte  => time.end_of_month
    ).size
  end
end
