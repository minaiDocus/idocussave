# -*- encoding : UTF-8 -*-
class AccountBookType
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug

  ENTRY_TYPE = %w(no expense buying selling bank)
  TYPES_NAME = %w(AC VT BC NDF)

  before_save :upcase_name, :sync_assignment, :sync_update_request, :set_request_type

  attr_accessor :force_assignment, :force_request_assignment
  
  referenced_in :owner, class_name: 'User', inverse_of: :my_account_book_types
  references_and_referenced_in_many :clients, class_name: 'User', inverse_of: :account_book_types
  references_and_referenced_in_many :requested_clients, class_name: 'User', inverse_of: :requested_account_book_types
  embeds_one :update_request, as: :update_requestable

  field :name,           type: String
  field :description,    type: String,  default: ""
  field :position,       type: Integer, default: 0
  field :entry_type,     type: Integer, default: 0
  field :account_number, type: String
  field :charge_account, type: String
  field :is_new,         type: Boolean
  field :request_type,   type: String,  default: "" # adding / updating /removing
  field :is_default,     type: Boolean, default: false
  
  slug :name

  validates_presence_of :name
  validates_presence_of :description
  validates :name,        length: { in: 2..10 }
  validates :description, length: { in: 2..50 }

  default_scope any_in: { request_type: ["",nil] }

  scope :adding,  where: { request_type: 'adding' }
  scope :default, where: { is_default: true }

  def update_requested_clients(ids)
    if ids.is_a?(String) && ids == 'empty'
      self.requested_clients = self.requested_clients - self.requested_clients.editable
    elsif owner.organization
      users = owner.organization.customers.find(ids)

      sub_users = self.requested_clients - users
      add_users = users - self.requested_clients

      sub_users.each do |user|
        self.requested_clients.delete(user)
      end
      add_users.each do |user|
        self.requested_clients << user
      end
    end
  end

  ################################# COMPTA #################################
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
  ###########################-- BEGIN REQUEST --###########################
  ############################### CLIENTS #################################

  def added_clients
    requested_clients - clients
  end

  def removed_clients
    clients - requested_clients
  end

  def is_clients_update_requested?
    if added_clients.empty? && removed_clients.empty?
      false
    else
      true
    end
  end

  def apply_clients_update_request
    if is_clients_update_requested?
      clients.clear
      requested_clients.each do |requested_client|
        clients << requested_client
      end
    end
  end

  def apply_clients_update_request!
    apply_clients_update_request
    save
  end

  def sync_with_clients
    requested_clients.clear
    clients.each do |client|
      requested_clients << client
    end
  end

  ################################# DESTROY ################################

  def request_destroy
    self.request_type = 'removing'
    save
  end

  def is_destroy_requested?
    self.request_type == "removing"
  end

  def cancel_destroy_request
    if self.is_new
      self.request_type = "adding"
    else
      if self.update_request && (self.update_request.values.present? || is_clients_update_requested?)
        self.request_type = "updating"
      else
        self.request_type = ""
      end
    end
    save
  end

  ################################# CHANGES ##################################

  def request_changes!
    self.update_request ||= UpdateRequest.new
    temp_changes = self.changes.delete_if { |e,v| v.nil? }
    self.update_request.temp_values = temp_changes
    self.update_request.save
  end

  def is_changes_requested?
    self.update_request.try(:values).present?
  end

  def apply_changes
    update_request.try(:apply)
  end

  def apply_update_request
    self.is_new = false
    self.request_type = ""
    apply_changes
  end

  def apply_update_request!
    apply_update_request
    save
  end

  ################################# GLOBAL ##################################

  def update_requestable_attributes
    [:name, :description, :entry_type, :account_number, :charge_account]
  end

  def set_request_type
    unless is_destroy_requested?
      if self.is_new
        self.request_type = 'adding'
      elsif is_update_requested?
        self.request_type = 'updating'
      else
        self.request_type = ''
      end
    end
  end

  def set_request_type!
    set_request_type
    save
  end

  def is_update_requested?
    is_new or is_changes_requested? or is_clients_update_requested? or is_destroy_requested?
  end

  def accept!
    if is_destroy_requested?
      destroy
    else
      apply_update_request
      apply_clients_update_request
      save
    end
  end

  #############################-- END REQUEST --#############################

  ################################# CLIENTS #################################
  def clients_count
    requested_clients.count
  end

  def clients_count_was
    clients.count
  end

  def clients_count_changed?
    clients.count == requested_clients.count ? false : true
  end
  ###########################################################################
  
  class << self
    def by_position
      asc([:position, :name])
    end

    def find_by_slug(txt)
      where(slug: txt).first
    end
  end
  
private

  def sync_assignment
    if 1 == @force_assignment.try(:to_i) || @force_assignment == true
      sync_with_clients
      update_request.values = {} if update_request
    end
  end

  def sync_update_request
    if update_request && (1 == @force_request_assignment.try(:to_i) || @force_request_assignment == true)
      update_requestable_attributes.each do |attribute|
        if self.send(attribute) == update_request.values[attribute.to_s]
          update_request.values.delete(attribute.to_s)
        end
      end
      update_request.temp_values = update_request.values
    end
  end

  def upcase_name
    self.name = self.name.upcase
  end
end
