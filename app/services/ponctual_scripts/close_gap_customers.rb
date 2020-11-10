class PonctualScripts::CloseGapCustomers < PonctualScripts::PonctualScript
  def self.execute()
    new().run
  end

  private

  def execute
    gap = Organization.find_by_code 'GAP'

    customers = gap.customers.active

    logger_infos("customers_size: #{customers.size}")

    customers.each do |customer|
      if customer.active?
        Subscription::Stop.new(customer, false).execute

        period = customer.subscription.current_period

        if customer.code == 'GAP%AYGGR'
          setRemainMonthPrice(period, 5)
        elsif customer.code == 'GAP%ACDC'
          setRemainMonthPrice(period, 3)
        elsif customer.code == 'GAP%NCSERVICES'
          setRemainMonthPrice(period, 4)
        end

        Billing::UpdatePeriod.new(period).execute

        logger_infos("customer: #{customer.code.to_s}; subscription_id: #{customer.subscription.id.to_s}, package: #{period.current_packages.to_s}")
        sleep 2
      end
    end
  end

  def setRemainMonthPrice(period, remaining_month)
    option = period.product_option_orders.where(name: 'extra_option', group_title: 'Autres').where("title LIKE '%Mini : engagement%'").first || ProductOptionOrder.new

    option.title       = "iDo'Mini : engagement #{remaining_month} mois restant(s)"
    option.name        = 'extra_option'
    option.duration    = 1
    option.group_title = 'Autres'
    option.is_an_extra = true
    option.is_frozen   = true
    option.price_in_cents_wo_vat = Subscription::Package.price_of(:ido_mini) * 100.0 * remaining_month

    period.product_option_orders = [option]
    period.save
  end
end
