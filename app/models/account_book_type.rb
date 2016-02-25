# -*- encoding : UTF-8 -*-
class AccountBookType
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug

  ENTRY_TYPE = %w(no expense buying selling)
  TYPES_NAME = %w(AC VT NDF)
  DOMAINS = ['', 'AC - Achats', 'VT - Ventes', 'BQ - Banque', 'OD - Opérations diverses', 'NF - Notes de frais']

  before_validation :upcase_name

  belongs_to :organization
  belongs_to :user

  has_many :fiduceo_retrievers, inverse_of: 'journal'

  embeds_many :expense_categories, cascade_callbacks: true

  accepts_nested_attributes_for :expense_categories, allow_destroy: true

  field :name,                           type: String
  field :pseudonym
  field :description,                    type: String,  default: ""
  field :position,                       type: Integer, default: 0
  field :entry_type,                     type: Integer, default: 0
  field :domain,                         type: String,  default: ''
  field :account_number,                 type: String
  field :default_account_number,         type: String
  field :charge_account,                 type: String
  field :default_charge_account,         type: String
  field :vat_account,                    type: String
  field :anomaly_account,                type: String
  field :is_default,                     type: Boolean, default: false
  field :is_expense_categories_editable, type: Boolean, default: false
  field :instructions,                   type: String

  slug :name

  validates_presence_of  :name
  validates_presence_of  :description
  validates_inclusion_of :entry_type, in: 0..3
  validates_inclusion_of :domain, in: DOMAINS
  validates_length_of    :instructions, maximum: 400
  validates :name,        length: { in: 2..10 }
  validates :description, length: { in: 2..50 }
  validate :format_of_name
  validate :uniqueness_of_name

  validates_presence_of :meta_account_number, if: Proc.new { |j| j.is_pre_assignment_processable? }
  validates_presence_of :meta_charge_account, if: Proc.new { |j| j.is_pre_assignment_processable? }
  validates_presence_of :vat_account,         if: Proc.new { |j| j.is_pre_assignment_processable? && j.try(:user).try(:options).try(:is_taxable) }
  validates_presence_of :anomaly_account,     if: Proc.new { |j| j.is_pre_assignment_processable? }

  scope :compta_processable,         -> { where(:entry_type.gt => 0) }
  scope :not_compta_processable,     -> { where(entry_type: 0) }
  scope :pre_assignment_processable, -> { where(:entry_type.gt => 1) }
  scope :default,                    -> { where(is_default: true) }

  before_save do |journal|
    unless journal.is_pre_assignment_processable?
      journal.account_number         = ''
      journal.default_account_number = ''
      journal.charge_account         = ''
      journal.default_charge_account = ''
      journal.vat_account            = ''
      journal.anomaly_account        = ''
    end
  end

  def account_type
    if @account_type
      @account_type
    else
      default_account? ? 'default' : 'waiting'
    end
  end

  def account_type=(value)
    @account_type=value
  end

  def meta_account_number
    default_account? ? default_account_number : account_number
  end

  def meta_account_number=(value)
    if account_type == 'default'
      self.default_account_number = value
      self.account_number = nil
    else
      self.account_number = value
      self.default_account_number = nil
    end
  end

  def meta_charge_account
    default_account? ? default_charge_account : charge_account
  end

  def meta_charge_account=(value)
    if account_type == 'default'
      self.default_charge_account = value
      self.charge_account = nil
    else
      self.charge_account = value
      self.default_charge_account = nil
    end
  end

  def info
    [self.name, self.description].join(' ')
  end

  def get_name
    pseudonym.presence || name
  end

  def compta_processable?
    entry_type > 0
  end

  def is_pre_assignment_processable?
    entry_type > 1
  end

  def compta_type
    return 'NDF' if self.entry_type == 1
    return 'AC'  if self.entry_type == 2
    return 'VT'  if self.entry_type == 3
    return nil
  end

  def default_account?
    self.default_account_number.present? || self.default_charge_account.present?
  end

  class << self
    def by_position
      asc([:position, :name])
    end
  end

  def is_open_for_modification?
    if created_at
      created_at + 24.hours > Time.now
    else
      true
    end
  end

  def reset_compta_attributes
    self.entry_type                     = 0
    self.account_number                 = nil   if account_number.present?
    self.default_account_number         = nil   if default_account_number.present?
    self.charge_account                 = nil   if charge_account.present?
    self.default_charge_account         = nil   if default_charge_account.present?
    self.vat_account                    = nil   if vat_account.present?
    self.anomaly_account                = nil   if anomaly_account.present?
    self.is_expense_categories_editable = false if is_expense_categories_editable.present?
  end

  def reset_compta_attributes!
    reset_compta_attributes
    save
  end

private

  def upcase_name
    self.name = self.name.upcase
  end

  def format_of_name
    errors.add(:name, :invalid) unless self.name.match(/\A[A-Z][A-Z0-9]+\z/)
  end

  def uniqueness_of_name
    if user
      journal = user.account_book_types.where(name: name).first
      if journal && journal != self
        errors.add(:name, :taken)
      end
    end
  end
end
