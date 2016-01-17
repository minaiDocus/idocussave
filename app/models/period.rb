# -*- encoding : UTF-8 -*-
class Period
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Locker

  belongs_to :user
  belongs_to :organization
  belongs_to :subscription
  has_many :documents, class_name: 'PeriodDocument'
  has_many :invoices
  has_many :orders
  embeds_many :product_option_orders, as: :product_optionable
  embeds_many :billings, class_name: 'PeriodBilling'
  embeds_one  :delivery, class_name: 'PeriodDelivery'

  field :start_at,       type: Time,    default: Proc.new { Time.now.beginning_of_month }
  field :end_at,         type: Time,    default: Proc.new { Time.now.end_of_month }
  field :duration,       type: Integer, default: 1
  field :is_centralized, type: Boolean, default: true

  field :price_in_cents_wo_vat,                    type: Integer, default: 0
  field :products_price_in_cents_wo_vat,           type: Integer, default: 0
  field :recurrent_products_price_in_cents_wo_vat, type: Integer, default: 0
  field :ponctual_products_price_in_cents_wo_vat,  type: Integer, default: 0
  field :orders_price_in_cents_wo_vat,             type: Integer, default: 0
  field :excesses_price_in_cents_wo_vat,           type: Integer, default: 0
  field :tva_ratio,                                type: Float,   default: 1.2

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

  field :documents_name_tags,      type: Array,   default: []
  field :pieces,                   type: Integer, default: 0
  field :pages,                    type: Integer, default: 0
  field :scanned_pieces,           type: Integer, default: 0
  field :scanned_sheets,           type: Integer, default: 0
  field :scanned_pages,            type: Integer, default: 0
  field :dematbox_scanned_pieces,  type: Integer, default: 0
  field :dematbox_scanned_pages,   type: Integer, default: 0
  field :uploaded_pieces,          type: Integer, default: 0
  field :uploaded_pages,           type: Integer, default: 0
  field :fiduceo_pieces,           type: Integer, default: 0
  field :fiduceo_pages,            type: Integer, default: 0
  field :paperclips,               type: Integer, default: 0
  field :oversized,                type: Integer, default: 0
  field :preseizure_pieces,        type: Integer, default: 0
  field :expense_pieces,           type: Integer, default: 0

  validates_inclusion_of :duration, in: [1, 3, 12]

  scope :monthly,   -> { where(duration: 1) }
  scope :quarterly, -> { where(duration: 3) }
  scope :annual,    -> { where(duration: 12) }

  scope :centralized,     -> { where(is_centralized: true) }
  scope :not_centralized, -> { where(is_centralized: false) }

  before_create :add_one_delivery
  before_save :set_start_at_and_end_at

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
    price_in_cents_of_excess_sheets + price_in_cents_of_excess_paperclips + price_in_cents_of_excess_oversized
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
    excess = scanned_sheets - max_sheets_authorized
    excess > 0 ? excess : 0
  end

  def excess_paperclips
    excess = paperclips - max_paperclips_authorized
    excess > 0 ? excess : 0
  end

  def excess_oversized
    excess = oversized - max_oversized_authorized
    excess > 0 ? excess : 0
  end

  def excess_uploaded_pages
    excess = uploaded_pages - max_upload_pages_authorized
    excess > 0 ? excess : 0
  end

  def excess_dematbox_scanned_pages
    excess = dematbox_scanned_pages - max_dematbox_scan_pages_authorized
    excess > 0 ? excess : 0
  end

  def excess_preseizure_pieces
    excess = preseizure_pieces - max_preseizure_pieces_authorized
    excess > 0 ? excess : 0
  end

  def excess_expense_pieces
    excess = expense_pieces - max_expense_pieces_authorized
    excess > 0 ? excess : 0
  end

  def excess_compta_pieces
    excess_preseizure_pieces + excess_expense_pieces
  end

  def compta_pieces
    preseizure_pieces + expense_pieces
  end

  def current
    desc(:start_at).first
  end

private

  def set_start_at_and_end_at
    if duration == 1
      self.start_at = start_at.beginning_of_month
      self.end_at   = start_at.end_of_month
    elsif duration == 3
      self.start_at = start_at.beginning_of_quarter
      self.end_at   = start_at.end_of_quarter
    elsif duration == 12
      self.start_at = start_at.beginning_of_year
      self.end_at   = start_at.end_of_year
    end
  end

  def add_one_delivery
    self.delivery = PeriodDelivery.new
  end
end
