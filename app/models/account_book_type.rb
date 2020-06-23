# -*- encoding : UTF-8 -*-
class AccountBookType < ApplicationRecord
  DOMAINS    = ['', 'AC - Achats', 'VT - Ventes', 'BQ - Banque', 'OD - Opérations diverses', 'NF - Notes de frais'].freeze
  ENTRY_TYPE = %w(no expense buying selling).freeze
  TYPES_NAME = %w(AC VT NDF).freeze

  audited

  attr_writer :account_type


  before_validation :upcase_name


  before_save do |journal|
    unless journal.is_pre_assignment_processable?
      journal.account_number         = ''
      journal.default_account_number = ''
      journal.charge_account         = ''
      journal.vat_account            = ''
      journal.vat_account_10         = ''
      journal.vat_account_8_5        = ''
      journal.vat_account_5_5        = ''
      journal.vat_account_2_1        = ''
      journal.anomaly_account        = ''
    end
  end

  has_one   :ibizabox_folder, foreign_key: :journal_id, dependent: :destroy

  has_many  :expense_categories
  has_many  :retrievers, inverse_of: 'journal', foreign_key: :journal_id

  belongs_to :user, optional: true
  belongs_to :organization, optional: true
  belongs_to :analytic_reference, inverse_of: :journals, optional: true


  accepts_nested_attributes_for :expense_categories, allow_destroy: true

  validate  :format_of_name
  validate  :uniqueness_of_name
  validates :name,        length: { in: 2..10 }
  validates :description, length: { in: 2..50 }
  validates_length_of   :instructions, maximum: 400
  validates_presence_of :name
  validates_presence_of :currency
  validates_presence_of :description
  validates_presence_of :vat_account,         if: proc { |j| j.is_pre_assignment_processable? && j.try(:user).try(:options).try(:is_taxable) }
  validates_presence_of :anomaly_account,     if: proc { |j| j.is_pre_assignment_processable? }
  validates_presence_of :meta_account_number, if: proc { |j| j.is_pre_assignment_processable? }
  validates_presence_of :meta_charge_account, if: proc { |j| j.is_pre_assignment_processable? }

  validates_inclusion_of :domain, in: DOMAINS
  validates_inclusion_of :entry_type, in: 0..3



  before_destroy do |journal|
    current_analytic = journal.analytic_reference
    current_analytic.destroy if current_analytic && !current_analytic.is_used_by_other_than?({ journals: [journal.id] })
  end

  scope :default,                    -> { where(is_default: true) }
  scope :by_position,                -> { order(position: :asc) }
  scope :compta_processable,         -> { where("entry_type > ?", 0) }
  scope :not_compta_processable,     -> { where(entry_type: 0) }
  scope :pre_assignment_processable, -> { where("entry_type > ?", 1) }



  def account_type
    if @account_type
      @account_type
    else
      default_account? ? 'default' : 'waiting'
    end
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
    charge_account || default_charge_account
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
    [name, description].join(' ')
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
    return 'NDF' if entry_type == 1
    return 'AC'  if entry_type == 2
    return 'VT'  if entry_type == 3
    nil
  end


  def default_account?
    default_account_number.present?
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
    self.vat_account                    = nil   if vat_account.present?
    self.vat_account_10                 = nil   if vat_account_10.present?
    self.vat_account_8_5                = nil   if vat_account_8_5.present?
    self.vat_account_5_5                = nil   if vat_account_5_5.present?
    self.vat_account_2_1                = nil   if vat_account_2_1.present?
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
    errors.add(:name, :invalid) unless name =~ /\A[A-Z][A-Z0-9]+\z/
  end

  def uniqueness_of_name
    if user
      journal = user.account_book_types.where(name: name).first

      errors.add(:name, :taken) if journal && journal != self
    end
  end

  def presence_of_vat_account
    if vat_account.blank?
      return errors.add(:vat_account, :blank) if user && user.try(:options).try(:is_taxable)
      errors.add(:vat_account, :blank) unless user  #require vat_account on shared journals if pre_assignement_processable
    end
  end
end
