# -*- encoding : UTF-8 -*-
class Period < ApplicationRecord
  serialize :documents_name_tags

  audited

  has_one  :delivery, class_name: 'PeriodDelivery'
  has_many :orders
  has_many :invoices
  has_many :billings, class_name: 'PeriodBilling'
  has_many :documents, class_name: 'PeriodDocument'
  has_many :product_option_orders, as: :product_optionable
  belongs_to :user, optional: true
  belongs_to :organization, optional: true
  belongs_to :subscription, optional: true

  validates_inclusion_of :duration, in: [1, 3, 12]


  scope :annual,    -> { where(duration: 12) }
  scope :monthly,   -> { where(duration: 1) }
  scope :quarterly, -> { where(duration: 3) }

  scope :current, -> { where('end_date >= ?', Date.today) }
  scope :paper_quota_reached_not_notified, -> { where(is_paper_quota_reached_notified: false) }
  scope :paper_quota_reached, -> { where('max_sheets_authorized <= scanned_sheets') }

  before_create :add_one_delivery
  before_create :set_start_date_and_end_date


  def self.period_name(duration, offset=0, current_time=Time.now)
    time = current_time
    time -= (duration * offset).month

    if duration == 1
      time.strftime('%Y%m')
    elsif duration == 3
      time = time.beginning_of_quarter
      "#{time.year}T#{(time.month/3.0).ceil}"
    elsif duration == 12
      time.year.to_s
    end
  end


  def amount_in_cents_wo_vat
    price_in_cents_wo_vat
  end


  def excesses_amount_in_cents_wo_vat
    excesses_price_in_cents_wo_vat
  end


  def price_in_cents_w_vat
    price_in_cents_wo_vat * tva_ratio
  end


  def products_price_in_cents_w_vat
    products_price_in_cents_wo_vat * tva_ratio
  end


  def ponctual_products_price_in_cents_w_vat
    ponctual_products_price_in_cents_wo_vat * tva_ratio
  end


  def recurrent_products_price_in_cents_w_vat
    recurrent_products_price_in_cents_wo_vat * tva_ratio
  end


  def excesses_price_in_cents_w_vat
    excesses_price_in_cents_wo_vat * tva_ratio
  end


  def total_vat
    price_in_cents_w_vat - price_in_cents_wo_vat
  end


  def price_in_cents_of_excess_sheets
    excess = excess_sheets

    if excess > 0
      excess * unit_price_of_excess_sheet
    else
      0
    end
  end


  def price_in_cents_of_excess_paperclips
    excess = excess_paperclips

    if excess > 0
      excess * unit_price_of_excess_paperclips
    else
      0
    end
  end


  def price_in_cents_of_excess_oversized
    excess = excess_oversized

    if excess > 0
      excess * unit_price_of_excess_oversized
    else
      0
    end
  end


  def price_in_cents_of_excess_scan
    price_in_cents_of_excess_sheets + price_in_cents_of_excess_oversized
  end


  def price_in_cents_of_excess_uploaded_pages
    excess = excess_uploaded_pages

    if excess > 0
      excess * unit_price_of_excess_upload
    else
      0
    end
  end


  def price_in_cents_of_excess_dematbox_scanned_pages
    excess = excess_dematbox_scanned_pages

    if excess > 0
      excess * unit_price_of_excess_dematbox_scan
    else
      0
    end
  end


  def price_in_cents_of_excess_compta_pieces
    price_in_cents_of_excess_preseizures + price_in_cents_of_excess_expenses
  end


  def price_in_cents_of_excess_preseizures
    excess = excess_preseizure_pieces

    if excess > 0
      excess * unit_price_of_excess_preseizure
    else
      0
    end
  end


  def price_in_cents_of_excess_expenses
    excess = excess_expense_pieces

    if excess > 0
      excess * unit_price_of_excess_expense
    else
      0
    end
  end


  def excess_sheets
    excess_of(:scanned_sheets, :max_sheets_authorized)
  end


  def excess_paperclips
    excess_of(:paperclips)
  end


  def excess_oversized
    excess_of(:oversized)
  end


  def excess_uploaded_pages
    excess_of(:uploaded_pages, :max_upload_pages_authorized)
  end


  def excess_dematbox_scanned_pages
    excess_of(:dematbox_scanned_pages, :max_dematbox_scan_pages_authorized)
  end


  def excess_preseizure_pieces
    excess_of(:preseizure_pieces)
  end


  def excess_expense_pieces
    excess_of(:expense_pieces)
  end


  def excess_compta_pieces
    excess_preseizure_pieces + excess_expense_pieces
  end


  def compta_pieces
    preseizure_pieces + expense_pieces
  end

  def type_name
    case duration
    when 1
      'mensuel'
    when 3
      'trimestre'
    when 12
      'annuel'
    end
  end

  def total_documents
    total_pieces + total_operations
  end

  def total_pieces
    pieces
  end

  def total_operations
    self.user.operations.where('created_at >= ? AND created_at <= ?', self.start_date, self.end_date).count
  end

private


  def excess_of(value, max_value=nil)
    max_value ||= "max_#{value.to_s}_authorized"
    return 0 unless self.respond_to?(value.to_sym) && self.respond_to?(max_value.to_sym)

    if excess_duration == 1
      excess = self.send(value.to_sym) - self.send(max_value.to_sym)
      excess > 0 ? excess : 0
    else
      subscription.excess_of(self, value, max_value, excess_duration)
    end
  end


  def set_start_date_and_end_date
    if duration == 1
      self.start_date = start_date.beginning_of_month
      self.end_date   = start_date.end_of_month
    elsif duration == 3
      self.start_date = start_date.beginning_of_quarter
      self.end_date   = start_date.end_of_quarter
    elsif duration == 12
      self.start_date = start_date.beginning_of_year
      self.end_date   = start_date.end_of_year
    end
  end


  def add_one_delivery
    self.delivery = PeriodDelivery.new
  end


  def excess_duration
    if subscription.try(:is_micro_package_active)
      12
    elsif subscription.try(:is_mini_package_active)
      3
    else
      1
    end
  end
end
