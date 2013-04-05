# -*- encoding : UTF-8 -*-
class AccountBookType
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug
  include ActiveModel::ForbiddenAttributesProtection

  ENTRY_TYPE = %w(no expense buying selling bank)
  TYPES_NAME = %w(AC VT BC NDF)

  before_save :upcase_name, :sync_assignment

  attr_accessor :force_assignment, :is_relation_updated, :removed_clients
  
  belongs_to :organization
  has_and_belongs_to_many :clients,           class_name: 'User', inverse_of: :account_book_types
  has_and_belongs_to_many :requested_clients, class_name: 'User', inverse_of: :requested_account_book_types

  has_one :request, as: :requestable, dependent: :destroy

  field :name,                   type: String
  field :description,            type: String,  default: ""
  field :position,               type: Integer, default: 0
  field :entry_type,             type: Integer, default: 0
  field :account_number,         type: String
  field :default_account_number, type: String
  field :charge_account,         type: String
  field :default_charge_account, type: String
  field :vat_account,            type: String
  field :anomaly_account,        type: String
  field :is_default,             type: Boolean, default: false
  
  slug :name

  validates_presence_of :name
  validates_presence_of :description
  validates :name,        length: { in: 2..10 }
  validates :description, length: { in: 2..50 }

  scope :default, where: { is_default: true }
  scope :compta_processable, where: { :entry_type.gt => 0 }

  def self.active
    select { |e| e.request.status != 'create' }
  end

  def info
    [self.name, self.description].join(' ')
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
    return 'CB'  if self.entry_type == 4
    return nil
  end

  def clients_count
    requested_clients.count
  end

  def clients_count_was
    clients.count
  end

  def clients_count_changed?
    clients.count == requested_clients.count ? false : true
  end
  
  class << self
    def by_position
      asc([:position, :name])
    end

    def find_by_slug(txt)
      where(slug: txt).first
    end
  end

  def requestable_on
    [
      :name,
      :description,
      :position,
      :entry_type,
      :default_account_number,
      :account_number,
      :default_charge_account,
      :charge_account,
      :vat_account,
      :anomaly_account,
      :is_default
    ]
  end

  def update_request_status!(temp_clients=(clients + requested_clients).uniq)
    request.update_relation_action_status!
    temp_clients.each do |client|
      client.request.update_relation_action_status!
    end
  end

private

  def sync_assignment
    if self.force_assignment.try(:to_i) == 1
      request.update_attribute(:attribute_changes, {})
    end
  end

  def upcase_name
    self.name = self.name.upcase
  end
end
