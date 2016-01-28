# -*- encoding : UTF-8 -*-
class Subscription
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :user
  # OR
  belongs_to :organization

  has_many :periods
  has_many :documents, class_name: 'PeriodDocument'
  has_many :invoices
  has_and_belongs_to_many :old_options, class_name: 'ProductOption', inverse_of: :subscribers # TODO remove me after migration
  has_and_belongs_to_many :options, class_name: 'SubscriptionOption', inverse_of: :subscribers

  field :period_duration, type: Integer, default: 1
  field :tva_ratio,       type: Float,   default: 1.2

  field :is_basic_package_active,      type: Boolean, default: false
  field :is_mail_package_active,       type: Boolean, default: false
  field :is_scan_box_package_active,   type: Boolean, default: false
  field :is_retriever_package_active,  type: Boolean, default: false
  field :is_annual_package_active,     type: Boolean, default: false
  field :number_of_journals,           type: Integer, default: 5
  field :is_blank_page_remover_active, type: Boolean, default: false
  field :is_pre_assignment_active,     type: Boolean, default: true
  field :is_stamp_active,              type: Boolean, default: false

  field :is_basic_package_to_be_disabled,      type: Boolean
  field :is_mail_package_to_be_disabled,       type: Boolean
  field :is_scan_box_package_to_be_disabled,   type: Boolean
  field :is_retriever_package_to_be_disabled,  type: Boolean
  field :is_blank_page_remover_to_be_disabled, type: Boolean
  field :is_pre_assignment_to_be_disabled,     type: Boolean
  field :is_stamp_to_be_disabled,              type: Boolean

  attr_accessor :is_to_apply_now

  validates :number_of_journals, numericality: { greater_than_or_equal_to: 5, less_than_or_equal_to: 10 }

  field :max_sheets_authorized,              type: Integer, default: 100 # numérisés
  field :max_upload_pages_authorized,        type: Integer, default: 200 # téléversés
  field :max_dematbox_scan_pages_authorized, type: Integer, default: 200 # iDocus'Box
  field :max_preseizure_pieces_authorized,   type: Integer, default: 100 # presaisies
  field :max_expense_pieces_authorized,      type: Integer, default: 100 # notes de frais
  field :max_paperclips_authorized,          type: Integer, default: 0   # attaches
  field :max_oversized_authorized,           type: Integer, default: 0   # hors format

  field :unit_price_of_excess_sheet,         type: Integer, default: 12  # numérisés
  field :unit_price_of_excess_upload,        type: Integer, default: 6   # téléversés
  field :unit_price_of_excess_dematbox_scan, type: Integer, default: 6   # iDocus'Box
  field :unit_price_of_excess_preseizure,    type: Integer, default: 12  # presaisies
  field :unit_price_of_excess_expense,       type: Integer, default: 12  # notes de frais
  field :unit_price_of_excess_paperclips,    type: Integer, default: 20  # attaches
  field :unit_price_of_excess_oversized,     type: Integer, default: 100 # hors format

  validates_inclusion_of :period_duration, in: [1, 3, 12]

  def current_period
    find_or_create_period(Time.now)
  end

  def find_period(time)
    periods.where(:start_at.lte => time.dup, :end_at.gte => time.dup).first
  end

  def create_period(time)
    period = Period.new(start_at: time.dup, duration: period_duration)
    period.subscription = self
    if organization
      period.organization = organization
    else
      period.user = user
      period.is_centralized = user.is_centralized
    end
    period.save
    UpdatePeriod.new(period).execute
    period
  end

  def find_or_create_period(time)
    find_period(time) || create_period(time)
  end

  def configured?
    is_basic_package_active     ||
    is_mail_package_active      ||
    is_scan_box_package_active  ||
    is_retriever_package_active ||
    is_annual_package_active
  end

  def to_be_configured?
    is_basic_package_active     && !is_basic_package_to_be_disabled     ||
    is_mail_package_active      && !is_mail_package_to_be_disabled      ||
    is_scan_box_package_active  && !is_scan_box_package_to_be_disabled  ||
    is_retriever_package_active && !is_retriever_package_to_be_disabled ||
    is_annual_package_active
  end

  def downgrade
    self.is_basic_package_active      = false if is_basic_package_to_be_disabled
    self.is_mail_package_active       = false if is_mail_package_to_be_disabled
    self.is_scan_box_package_active   = false if is_scan_box_package_to_be_disabled
    self.is_retriever_package_active  = false if is_retriever_package_to_be_disabled
    self.is_blank_page_remover_active = false if is_blank_page_remover_to_be_disabled
    self.is_pre_assignment_active     = false if is_pre_assignment_to_be_disabled
    self.is_stamp_active              = false if is_stamp_to_be_disabled
  end

  def light_package?
    !is_annual_package_active
  end
end
