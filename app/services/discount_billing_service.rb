# -*- encoding : UTF-8 -*-
class DiscountBillingService
  def initialize(organization)
    @organization = organization
  end

  def self.update_period(period)
    discount = new(period.organization)

    period.with_lock do
      period.product_option_orders.where(name: 'discount_option').destroy_all
      option = period.product_option_orders.new
      option.title       = discount.title
      option.name        = 'discount_option'
      option.duration    = 1
      option.group_title = 'Autres'
      option.is_an_extra = true
      option.price_in_cents_wo_vat = discount.total_amount_in_cents
      period.save
    end

    UpdatePeriodPriceService.new(period).execute
  end

  def title
    discount_title = []

    if is_iDoMini_discount?
      discount_title << "iDoMini : #{unit_amount(:iDoMini)} € x #{quantity_of(:iDoMini)}"
    else
      discount_title << "Abo. mensuels : #{unit_amount(:subscription)} € x #{quantity_of(:subscription)}" if unit_amount(:subscription) < 0
      discount_title << "iDofacb. : #{unit_amount(:retriever)} € x #{quantity_of(:retriever)}" if unit_amount(:retriever) < 0
    end

    discount_title << '-50 dossiers' if discount_title.empty?
    "Remise sur CA (#{discount_title.join(', ')})"
  end

  def total_amount_in_cents
    total_amount = 0

    if is_iDoMini_discount?
      total_amount += amount_in_cents_of(:iDoMini)
    else
      total_amount += amount_in_cents_of(:subscription)
      total_amount += amount_in_cents_of(:retriever)
    end
  end

  def amount_in_cents_of(option)
    unit_amount(option.to_sym) * quantity_of(option.to_sym) * 100.0
  end

  def quantity_of(option)
    case option.to_s
      when 'subscription'
        concerned_subscriptions.where("subscriptions.is_basic_package_active = ? OR subscriptions.is_scan_box_package_active = ? OR subscriptions.is_mail_package_active = ?", true, true, true).size
      when 'retriever'
        concerned_subscriptions.where("subscriptions.is_retriever_package_active" => true).size
      when 'iDoMini'
        concerned_subscriptions.where("subscriptions.is_mini_package_active" => true).size
      else 0
    end
  end

  def unit_amount(option)
    if option.to_s == 'iDoMini'
      quantity_of(option) > 75 ? -4 : 0
    else
      amount = get_amount_policy option
      amount[:retriever] = 0.0 if @organization.subscription.retriever_price_option.to_s == 'reduced_retriever'
      amount[option]
    end
  end

  def apply_special_policy?
    %w(GMBA).include? @organization.code
  end

  private

  def is_iDoMini_discount?
    unit_amount(:iDoMini) < 0
  end

  def customers
    @organization.customers.active
  end

  def concerned_subscriptions
    @concerned_subscriptions ||= customers.joins(:subscription).where("subscriptions.period_duration" => 1, "subscriptions.is_micro_package_active" => false)
  end

  def get_amount_policy(option)
    if apply_special_policy?
      case quantity_of(option)
        when (0..50)
          {subscription: -1, retriever: 0}
        when (51..150)
          {subscription: -1.5, retriever: -0.5}
        when (151..200)
          {subscription: -2, retriever: -0.75}
        when (201..250)
          {subscription: -2.5, retriever: -1}
        when (251..350)
          {subscription: -3, retriever: -1.25}
        when (351..500)
          {subscription: -4, retriever: -1.50}
        when (501..Float::INFINITY)
          {subscription: -5, retriever: -2}
      end
    else
      case quantity_of(option)
        when (0..50)
          {subscription: 0, retriever: 0}
        when (51..100)
          {subscription: -1, retriever: 0}
        when (101..200)
          {subscription: -1.5, retriever: -0.5}
        when (201..350)
          {subscription: -2, retriever: -1}
        when (351..500)
          {subscription: -3, retriever: -1.25}
        when (501..Float::INFINITY)
          {subscription: -4, retriever: -1.5}
      end
    end
  end

end