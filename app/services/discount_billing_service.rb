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
      discount_title << "iDoMini : #{unit_amount(:iDoMini)} € x #{classic_quantity_of(:iDoMini)}"
    else
      discount_title << "Abo. mensuels : #{unit_amount(:subscription)} € x #{classic_quantity_of(:subscription)}" if unit_amount(:subscription) < 0
      discount_title << "iDofacb. : #{unit_amount(:retriever)} € x #{classic_quantity_of(:retriever)}" if unit_amount(:retriever) < 0
    end

    discount_title << '- 75 dossiers' if discount_title.empty?
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
    unit_amount(option.to_sym) * classic_quantity_of(option.to_sym) * 100.0
  end

  def quantity_of(option)
    if extentis_group.include? @organization.code
      special_extentis_quantity_of option
    else
      classic_quantity_of option
    end
  end

  def unit_amount(option)
    amount = get_amount_policy option
    amount[:retriever] = 0.0 if @organization.subscription.try(:retriever_price_option).to_s == 'reduced_retriever'
    return amount[:subscription].to_i if option.to_s == 'iDoMini'
    amount[option]
  end

  def apply_special_policy?
    groups = []
    groups.include? @organization.code
  end

  private

  def classic_quantity_of(option)
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

  def is_iDoMini_discount?
    unit_amount(:iDoMini) < 0
  end

  def customers
    @organization.customers.active
  end

  def concerned_subscriptions
    @concerned_subscriptions ||= customers.joins(:subscription).where("subscriptions.period_duration" => 1, "subscriptions.is_micro_package_active" => false)
  end

  def get_amount_policy(package_sym)
    package   = (package_sym.to_s == 'iDoMini')? :ido_mini : :default
    quantity  = quantity_of(package_sym)
    result    = { subscription: 0, retriever: 0 }

    SubscriptionPackage.discount_billing_of(package, apply_special_policy?).each do |discount|
      if discount[:limit].include?(quantity.to_i)
        result = { subscription: discount[:subscription_price], retriever: discount[:retriever_price] }
        break
      end
    end

    result
  end


  def extentis_group
    # ['FBC','FIDA','FIDC', 'EG']
    return @extentis_group if @extentis_group.present?

    group = OrganizationGroup.where(id: 2, name: 'Extentis').first
    @extentis_group = group.present? ? group.organizations.collect(&:code) : ["FIDA", "FIDC", "FBC", "EG"]
    @extentis_group
  end

  def special_extentis_quantity_of(option)
    case option.to_s
      when 'subscription'
        extentis_subscriptions.where("subscriptions.is_basic_package_active = ? OR subscriptions.is_scan_box_package_active = ? OR subscriptions.is_mail_package_active = ?", true, true, true).size
      when 'retriever'
        extentis_subscriptions.where("subscriptions.is_retriever_package_active" => true).size
      when 'iDoMini'
        extentis_subscriptions.where("subscriptions.is_mini_package_active" => true).size
      else 0
    end
  end

  def extentis_customers
    User.customers.active.where(organization_id: Organization.billed.where(code: extentis_group).collect(&:id))
  end

  def extentis_subscriptions
    @extentis_subscriptions ||= extentis_customers.joins(:subscription).where("subscriptions.period_duration" => 1, "subscriptions.is_micro_package_active" => false)
  end

end