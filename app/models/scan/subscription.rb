# -*- encoding : UTF-8 -*-
class Scan::Subscription < Subscription
  include ActiveModel::ForbiddenAttributesProtection

  has_many :periods,   class_name: "Scan::Period",   inverse_of: :subscription
  has_many :documents, class_name: "Scan::Document", inverse_of: :subscription

  field :max_sheets_authorized,              type: Integer, default: 100 # numérisés
  field :max_upload_pages_authorized,        type: Integer, default: 200 # téléversés
  field :max_dematbox_scan_pages_authorized, type: Integer, default: 200 # iDocus'Box
  field :max_preseizure_pieces_authorized,   type: Integer, default: 100 # presaisies
  field :max_expense_pieces_authorized,      type: Integer, default: 100 # notes de frais
  field :max_paperclips_authorized,          type: Integer, default: 0   # attaches
  field :max_oversized_authorized,           type: Integer, default: 0   # hors format

  field :unit_price_of_excess_sheet,         type: Integer, default: 12  # numérisés
  field :unit_price_of_excess_upload,        type: Integer, default: 6 # téléversés
  field :unit_price_of_excess_dematbox_scan, type: Integer, default: 6 # iDocus'Box
  field :unit_price_of_excess_preseizure,    type: Integer, default: 12  # presaisies
  field :unit_price_of_excess_expense,       type: Integer, default: 12  # notes de frais
  field :unit_price_of_excess_paperclips,    type: Integer, default: 20  # attaches
  field :unit_price_of_excess_oversized,     type: Integer, default: 100 # hors format

  def current_period
    find_or_create_period(Time.now)
  end

  def find_period(time)
    periods.where(:start_at.lte => time, :end_at.gte => time).first
  end

  def create_period(time)
    period = Scan::Period.new(start_at: time, duration: period_duration)
    period.subscription = self
    if organization
      period.organization = organization
    else
      period.user = user
      period.is_centralized = user.is_centralized
    end
    period.save
    UpdatePeriodService.new(period).execute
    period
  end

  def find_or_create_period(time)
    find_period(time) || create_period(time)
  end

  def remove_not_reusable_options
    self.options = self.options.select { |option| option.duration == 0 }
    save
    self.options
  end

  def total
    result = 0
    if organization
      subscription_ids = Scan::Subscription.any_in(:user_id => organization.customers.map { |e| e.id }).distinct(:_id)
      periods = Scan::Period.any_in(subscription_id: subscription_ids).
           where(:start_at.lt => Time.now, :end_at.gt => Time.now)
      result = PeriodService.total_price_in_cents_wo_vat(Time.now, periods)
      ops = nil
      if(p = find_period(Time.now))
        ops = p.product_option_orders
      else
        ops = self.options
      end
      ops.where(:group_position.gte => 1000).each do |option|
        result += option.price_in_cents_wo_vat
      end
    else
      result = find_period(Time.now).try(:total_price_in_cents_wo_vat) || 0
    end
    result
  end

  def products_price_in_cents_wo_vat
    current_period.product_option_orders.sum(:price_in_cents_wo_vat) || 0
  end

  def products_price_in_cents_w_vat
    products_price_in_cents_wo_vat * tva_ratio
  end

  def copyable_keys
    [
      :max_sheets_authorized,
      :max_upload_pages_authorized,
      :max_preseizure_pieces_authorized,
      :max_expense_pieces_authorized,
      :max_paperclips_authorized,
      :max_oversized_authorized,
      :max_dematbox_scan_pages_authorized,
      :unit_price_of_excess_sheet,
      :unit_price_of_excess_upload,
      :unit_price_of_excess_preseizure,
      :unit_price_of_excess_expense,
      :unit_price_of_excess_paperclips,
      :unit_price_of_excess_oversized,
      :unit_price_of_excess_dematbox_scan
    ]
  end
end
