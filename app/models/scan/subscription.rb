# -*- encoding : UTF-8 -*-
class Scan::Subscription < Subscription
  include ActiveModel::ForbiddenAttributesProtection

  has_many :periods,   class_name: "Scan::Period",   inverse_of: :subscription
  has_many :documents, class_name: "Scan::Document", inverse_of: :subscription

  attr_accessor :is_to_spreading, :update_period, :options

  # quantité limite
  field :max_sheets_authorized,              type: Integer, default: 100 # numérisés
  field :max_upload_pages_authorized,        type: Integer, default: 200 # téléversés
  field :quantity_of_a_lot_of_upload,        type: Integer, default: 1   # téléversés
  field :max_dematbox_scan_pages_authorized, type: Integer, default: 200 # iDocus'Box
  field :quantity_of_a_lot_of_dematbox_scan, type: Integer, default: 1   # iDocus'Box
  field :max_preseizure_pieces_authorized,   type: Integer, default: 100 # presaisies
  field :max_expense_pieces_authorized,      type: Integer, default: 100 # notes de frais
  field :max_paperclips_authorized,          type: Integer, default: 0   # attaches
  field :max_oversized_authorized,           type: Integer, default: 0   # hors format
  # prix excès
  field :unit_price_of_excess_sheet,      type: Integer, default: 12  # numérisés
  field :price_of_a_lot_of_upload,        type: Integer, default: 6   # téléversés
  field :price_of_a_lot_of_dematbox_scan, type: Integer, default: 6   # iDocus'Box
  field :unit_price_of_excess_preseizure, type: Integer, default: 12  # presaisies
  field :unit_price_of_excess_expense,    type: Integer, default: 12  # notes de frais
  field :unit_price_of_excess_paperclips, type: Integer, default: 20  # attaches
  field :unit_price_of_excess_oversized,  type: Integer, default: 100 # hors format

  before_create :set_category, :create_period
  before_save :check_propagation
  before_save :update_current_period, if: Proc.new { |e| e.persisted? }

  def set_category
  	self.category = 1
  end

  def code
  	self.user.try(:code)
  end

  def code=(vcode)
  	self.user = User.where(code: vcode).first
  end

  def find_period(time)
    periods.where(:start_at.lte => time, :end_at.gte => time).first
  end

  def _find_period(time)
    periods.select do |period|
      period.start_at < time and period.end_at > time
    end.first
  end

  def find_or_create_period(time)
    period = find_period(time)
    if period
      period
    else
      period = Scan::Period.new(start_at: time, duration: period_duration)
      period.subscription = self
      if organization
        period.organization = self.organization
      else
        period.user = self.user
        period.is_centralized = self.user.is_centralized
      end
      period.set_product_option_orders self.product_option_orders

      period.duration = self.period_duration
      copyable_keys.each do |key|
        period[key] = self[key]
      end

      period.save
      period
    end
  end

  def remove_not_reusable_options
    product_option_orders.each { |e| e.destroy if e.duration == 1 }
    save
    product_option_orders
  end

  def copy!(scan_subscription)
    self.end_in = scan_subscription.end_in
    self.payment_type = scan_subscription.payment_type
    self.period_duration = scan_subscription.period_duration
    copyable_keys.each do |key|
      self[key] = scan_subscription[key]
    end
    self.copy_to_options! scan_subscription.product_option_orders

    self.save
  end

  def propagate_changes_for(clients)
    clients.each do |client|
      client.find_or_create_scan_subscription.copy! self
    end
  end

  def propagate_changes
   propagate_changes_for organization.customers.active
  end

  def check_propagation
    if is_to_spreading.try(:to_i) == 1 and organization
      propagate_changes
    end
  end

  def create_period
    find_or_create_period(Time.now)
  end

  def current_period
    find_or_create_period(Time.now)
  end

  def update_current_period
    if (self.user && self.user.active?) || self.organization
      if self.organization
        options = self.product_option_orders.where(:group_position.gte => 1000)
      else
        options = self.product_option_orders
      end
      period = current_period
      period.set_product_option_orders(options)

      period.duration = self.period_duration
      copyable_keys.each do |key|
        period[key] = self[key]
      end

      period.save
    end
  end

  def total
    result = 0
    if organization
      subscription_ids = Scan::Subscription.any_in(:user_id => organization.customers.map { |e| e.id }).distinct(:_id)
      periods = Scan::Period.any_in(subscription_id: subscription_ids).
           where(:start_at.lt => Time.now, :end_at.gt => Time.now)
      result = PeriodService.total_price_in_cents_wo_vat(Time.now, periods)
      acs = nil
      if(p = find_period(Time.now))
        acs = p
      else
        acs = self
      end
      acs.product_option_orders.where(:group_position.gte => 1000).each do |option|
        result += option.price_in_cents_wo_vat
      end
    else
      result = find_period(Time.now).try(:total_price_in_cents_wo_vat) || 0
    end
    result
  end

  def products_price_in_cents_wo_vat
    product_option_orders.user_editable.sum(:price_in_cents_wo_vat) || 0
  end

  def products_price_in_cents_w_vat
    products_price_in_cents_wo_vat * self.tva_ratio
  end

  def copy_to_options!(options)
    self.product_option_orders = []
    new_options = copy_options(options)
    new_options.each do |new_option|
      self.product_option_orders << new_option
    end
    new_options
  end

  def copyable_keys
    [
      :max_sheets_authorized,
      :max_upload_pages_authorized,
      :quantity_of_a_lot_of_upload,
      :max_preseizure_pieces_authorized,
      :max_expense_pieces_authorized,
      :max_paperclips_authorized,
      :max_oversized_authorized,
      :max_dematbox_scan_pages_authorized,
      :quantity_of_a_lot_of_dematbox_scan,
      :unit_price_of_excess_sheet,
      :price_of_a_lot_of_upload,
      :unit_price_of_excess_preseizure,
      :unit_price_of_excess_expense,
      :unit_price_of_excess_paperclips,
      :unit_price_of_excess_oversized,
      :price_of_a_lot_of_dematbox_scan
    ]
  end

protected

  def copy_options(options)
    new_options = []
    options.each do |option|
      product_option_order = ProductOptionOrder.new
      product_option_order.fields.keys.each do |k|
        setter =  (k+"=").to_sym
        value = option.send(k)
        product_option_order.send(setter, value)
      end
      new_options << product_option_order
    end
    new_options
  end
end
