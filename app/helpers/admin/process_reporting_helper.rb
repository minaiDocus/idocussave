# frozen_string_literal: true

module Admin::ProcessReportingHelper
  def sum_of_scanned_sheets(organization, time)
    organization.temp_documents.scan.where('created_at >= ? AND created_at <= ?', time.dup, time.end_of_month).where('(state = ? AND is_an_original = ?) OR state = ?', 'processed', 1, 'bundled').size
  end

  def sum_of_bundled(organization, time)
    total = organization.temp_documents.bundled.where(delivery_type: 'scan').where('created_at >= ? AND created_at <= ?', time.dup, time.end_of_month).count

    total += organization.temp_documents.bundled.where(delivery_type: %w[upload dematbox_scan]).where('created_at >= ? AND created_at <= ?', time.dup, time.end_of_month).sum(:pages_number).to_i || 0

    total
  end

  def sum_of_pre_assignments(organization, time)
    total = 0

    total += organization.expenses.where('created_at >= ? AND created_at <= ?', time.dup, time.end_of_month).count
    total += Pack::Report::Preseizure.unscoped.where(organization: organization).where.not(piece_id: [nil]).where('created_at >= ? AND created_at <= ?', time.dup, time.end_of_month).count

    total
  end

  def sum_of_requested_kits(customers, time)
    if time < Time.local(2016)
      pattern = /env.*papier.*numérisation/i

      customer_ids = Period.where(user_id: customers.map(&:id)).where('created_at >= ? AND created_at <= ?', time.dup, time.end_of_month).reject do |period|
        options = period.product_option_orders.select do |option|
          option.title.match(pattern) || (option.group_title.match(pattern) && option.title.match(/Oui/i))
        end

        options.empty?
      end.map(&:user_id).uniq

      previous_month = time - 1.month

      previous_count = Period.where(user_id: customer_ids).where('created_at >= ? AND created_at <= ?', previous_month, previous_month.end_of_month).reject do |period|
        options = period.product_option_orders.select do |option|
          option.title.match(pattern) || (option.group_title.match(pattern) && option.title.match(/Oui/i))
        end

        options.empty?
      end.size

      customer_ids.size - previous_count
    else
      Order.paper_sets.billed.where(user_id: customers.map(&:id)).where('created_at >= ? AND created_at <= ?', time.dup, time.end_of_month).count
    end
  end

  def sum_of_sent_kits(organization, time)
    organization.paper_processes.kits.where('created_at >= ? AND created_at <= ?', time.dup, time.end_of_month).size
  end

  def sum_of_receipts(organization, time)
    organization.paper_processes.receipts.where('created_at >= ? AND created_at <= ?', time.dup, time.end_of_month).size
  end

  def sum_of_paperclips(customers, time)
    periods = Period.where(user_id: customers.map(&:id)).where('created_at >= ? AND created_at <= ?', time.dup, time.end_of_month)

    periods.map do |period|
      Billing::PeriodBilling.new(period).data(:paperclips, time.month)
    end.sum
  end

  def sum_of_oversized(customers, time)
    periods = Period.where(user_id: customers.map(&:id)).where('created_at >= ? AND created_at <= ?', time.dup, time.end_of_month)

    periods.map do |period|
      Billing::PeriodBilling.new(period).data(:oversized, time.month)
    end.sum
  end

  def sum_of_returns_500(organization, time)
    organization.paper_processes.returns.l500.where('created_at >= ? AND created_at <= ?', time.dup, time.end_of_month).size
  end

  def sum_of_returns_1000(organization, time)
    organization.paper_processes.returns.l1000.where('created_at >= ? AND created_at <= ?', time.dup, time.end_of_month).size
  end

  def sum_of_returns_3000(organization, time)
    organization.paper_processes.returns.l3000.where('created_at >= ? AND created_at <= ?', time.dup, time.end_of_month).size
  end
end
