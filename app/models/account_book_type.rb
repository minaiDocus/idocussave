# -*- encoding : UTF-8 -*-
class AccountBookType
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug
  include ActiveModel::ForbiddenAttributesProtection

  ENTRY_TYPE = %w(no expense buying selling)
  TYPES_NAME = %w(AC VT NDF)
  DOMAINS = ['', 'AC - Achats', 'VT - Ventes', 'BQ - Banque', 'OD - Opérations diverses', 'NF - Notes de frais']

  before_save :upcase_name

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

  scope :compta_processable, where: { :entry_type.gt => 0 }
  scope :default, where: { is_default: true }

  def info
    [self.name, self.description].join(' ')
  end

  def get_name
    pseudonym.presence || name
  end

  def compta_processable?
    if entry_type > 0
      true
    else
      false
    end
  end

  def compta_type
    return 'NDF' if self.entry_type == 1
    return 'AC'  if self.entry_type == 2
    return 'VT'  if self.entry_type == 3
    return nil
  end

  class << self
    def by_position
      asc([:position, :name])
    end

    def find_by_slug(txt)
      where(slug: txt).first
    end
  end

private

  def upcase_name
    self.name = self.name.upcase
  end
end
