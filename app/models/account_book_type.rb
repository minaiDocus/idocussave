# -*- encoding : UTF-8 -*-
class AccountBookType
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug
  include ActiveModel::ForbiddenAttributesProtection

  ENTRY_TYPE = %w(no expense buying selling)
  TYPES_NAME = %w(AC VT NDF)

  before_save :upcase_name, :sync_assignment

  attr_accessor :force_assignment, :is_relation_updated, :removed_clients
  
  belongs_to :organization
  has_and_belongs_to_many :clients,           class_name: 'User', inverse_of: :account_book_types
  has_and_belongs_to_many :requested_clients, class_name: 'User', inverse_of: :requested_account_book_types

  has_one :request, as: :requestable, dependent: :destroy
  has_many :fiduceo_retrievers, inverse_of: 'journal'

  embeds_many :expense_categories, cascade_callbacks: true
  
  accepts_nested_attributes_for :expense_categories, allow_destroy: true
  
  field :name,                           type: String
  field :description,                    type: String,  default: ""
  field :position,                       type: Integer, default: 0
  field :entry_type,                     type: Integer, default: 0
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
  validates_length_of    :instructions, maximum: 400
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
      :instructions,
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
      client_ids = self['client_ids']
      requested_client_ids = self['requested_client_ids']
      added_client_ids = client_ids.reject { |id| id.in? requested_client_ids }
      added_client_ids.each do |id|
        user = User.find id
        requested_clients << user
      end
      removed_client_ids = requested_client_ids.reject { |id| id.in? client_ids }
      removed_client_ids.each do |id|
        user = requested_clients.select { |c| c.id == id }.first
        requested_clients.delete(user)
      end
      request.update_attribute(:attribute_changes, {})
      request.update_relation_action_status!
    end
  end

  def upcase_name
    self.name = self.name.upcase
  end
end
