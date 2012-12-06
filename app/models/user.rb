# -*- encoding : UTF-8 -*-
class User
  include Mongoid::Document
  include Mongoid::Timestamps
  # Include default devise modules. Others available are:
  # :registerable, :token_authenticatable, :lockable and :timeoutable
  devise :database_authenticatable, :confirmable,
         :recoverable, :rememberable, :validatable, :trackable

  ## Database authenticatable
  field :email
  field :encrypted_password, type: String, default: ""

  validates_presence_of :email, :encrypted_password

  ## Recoverable
  field :reset_password_token,   type: String
  field :reset_password_sent_at, type: Time

  ## Rememberable
  field :remember_created_at, type: Time

  ## Trackable
  field :sign_in_count,      type: Integer, default: 0
  field :current_sign_in_at, type: Time
  field :last_sign_in_at,    type: Time
  field :current_sign_in_ip, type: String
  field :last_sign_in_ip,    type: String

  ## Confirmable
  field :confirmation_token,   type: String
  field :confirmed_at,         type: Time
  field :confirmation_sent_at, type: Time
  field :unconfirmed_email,    type: String # Only if using reconfirmable

  ## Lockable
  # field :failed_attempts, type: Integer, default: 0 # Only if lock strategy is :failed_attempts
  # field :unlock_token,    type: String # Only if unlock strategy is :email or :both
  # field :locked_at,       type: Time

  ## Token authenticatable
  # field :authentication_token, type: String

  field :is_admin,                       type: Boolean, default: false
  field :balance_in_cents,               type: Float,   default: 0.0
  field :use_debit_mandate,              type: Boolean, default: false
  field :code,                           type: String
  field :first_name,                     type: String
  field :last_name,                      type: String
  field :company,                        type: String
  field :is_prescriber,                  type: Boolean, default: false
  field :inactive_at,                    type: Time
  field :dropbox_delivery_folder,        type: String,  default: 'iDocus_delivery/:code/:year:month/:account_book/'
  field :is_dropbox_extended_authorized, type: Boolean, default: false
  field :is_centralizer,                 type: Boolean, default: true
  field :is_detail_authorized,           type: Boolean, default: false
  field :is_reminder_email_active,       type: Boolean, default: true

  NOTHING  = 0
  ADDING   = 1
  UPDATING = 2
  REQUEST_TYPE_NAME = %w(nothing adding updating)

  field :is_new,                         type: Boolean, default: false
  field :is_disabled,                    type: Boolean, default: false
  field :is_editable,                    type: Boolean, default: true
  field :request_type,                   type: Integer, default: 0

  field :stamp_name,                     type: String,  default: ':code :account_book :period :piece_num'
  field :is_stamp_background_filled,     type: Boolean, default: false

  attr_accessor :client_ids, :is_inactive
  attr_protected :is_admin, :is_prescriber

  # FIXME use another way
  before_save :set_timestamps_of_addresses

  embeds_many :addresses
  embeds_one :update_request, as: :update_requestable

  references_many :clients,  class_name: "User", inverse_of: :prescriber
  referenced_in :prescriber, class_name: "User", inverse_of: :clients

  references_many :periods,            class_name: "Scan::Period",       inverse_of: :user
  references_many :scan_subscriptions, class_name: "Scan::Subscription", inverse_of: :user
  
  references_many :own_packs, class_name: "Pack", inverse_of: :owner
  references_and_referenced_in_many :packs
  
  references_many :my_account_book_types, class_name: "AccountBookType", inverse_of: :owner
  references_and_referenced_in_many :account_book_types,  inverse_of: :clients
  references_and_referenced_in_many :requested_account_book_types, class_name: "AccountBookType",  inverse_of: :requested_clients

  references_and_referenced_in_many :sharers, class_name: "User", inverse_of: :share_with
  references_and_referenced_in_many :share_with, class_name: "User", inverse_of: :sharers

  references_many :reminder_emails, autosave: true
  references_many :invoices
  references_many :credits
  references_many :document_tags
  references_many :subscriptions
  references_many :backups
  references_many :uploaded_files
  references_many :remote_files, dependent: :destroy
  references_many :log_visits, class_name: 'Log::Visit', inverse_of: :user
  references_one :composition
  references_one :debit_mandate
  references_one :external_file_storage, autosave: true
  references_one :file_sending_kit
  references_one :csv_outputter, autosave: true
  
  scope :prescribers,                 where: { is_prescriber: true }
  scope :dropbox_extended_authorized, where: { is_dropbox_extended_authorized: true }
  scope :active,                      where: { inactive_at: nil }
  
  before_save :format_name, :update_clients, :set_inactive_at, :set_request_type

  accepts_nested_attributes_for :external_file_storage
  accepts_nested_attributes_for :addresses,             allow_destroy: true
  accepts_nested_attributes_for :reminder_emails,       allow_destroy: true
  accepts_nested_attributes_for :csv_outputter

  def active
    inactive_at == nil
  end
  
  def name
    [self.first_name,self.last_name].join(' ') || self.email
  end

  def info
    [self.code,self.company,self.name].reject { |e| e.blank? }.join(' - ')
  end

  def self.find_by_email(param)
    User.where(email: param).first
  end
  
  def self.find_by_emails(params)
    User.any_in(email: params).entries
  end

  def self.find_by_code(code)
    User.where(code: code).first
  end

  def is_subscribed_to_category(number)
    if self.subscriptions.where(category: number).first
      true
    else
      false
    end
  end
  
  def is_active?
    inactive_at.nil? ? true : false
  end
  
  def is_inactive?
    !is_active?
  end

  def find_or_create_scan_subscription
    if scan_subscriptions.any?
      scan_subscriptions.current
    else
      scan_subscription = Scan::Subscription.new
      scan_subscription.user = self
      scan_subscription.save
      scan_subscription
    end
  end
  
  def shipping_address
    self.addresses.for_shipping.first
  end
  
  def billing_address
    self.addresses.for_billing.first
  end
  
  def find_or_create_external_file_storage
    external_file_storage || ExternalFileStorage.create(user_id: self.id).reload
  end

  def find_or_create_efs
    find_or_create_external_file_storage
  end

  def find_or_create_file_sending_kit
    if self.is_prescriber
      file_sending_kit || FileSendingKit.create(user_id: self.id, title: 'Title', logo_path: '/logo/path', left_logo_path: '/left/logo/path', right_logo_path: '/right/logo/path')
    else
      nil
    end
  end
  
  def propagate_stamp_name
    if self.is_prescriber
      self.clients.each { |client| client.update_attribute(:stamp_name, self.stamp_name) }
    end
  end

  def csv_outputter!
    csv_outputter || CsvOutputter.create(user_id: self.id)
  end

  def propagate_stamp_background
    if self.is_prescriber
      self.clients.each { |client| client.update_attribute(:is_stamp_background_filled, self.is_stamp_background_filled) }
    end
  end

  def propagate_is_editable
    if self.is_prescriber
      self.clients.each { |client| client.update_attribute(:is_editable, self.is_editable) }
    end
  end
  
  def update_requestable_attributes
    [:email,:last_name,:first_name,:company,:code]
  end

  def active_for_authentication?
    super && !self.is_disabled
  end

  def activate!
    self.is_new = false
    self.is_disabled = false
    save
  end

  def accept!
    if update_request
      update_request.apply
      update_request.values = {}
    end
    save
  end

  def is_update_requested?
    result = false
    # user
    result = true if self.update_request.try(:values).present?
    # journals
    if self.is_prescriber
      my_account_book_types.unscoped.each do |account_book_type|
        result = true if account_book_type.is_update_requested?
      end
    else
      result = true if account_book_types.unscoped.entries != requested_account_book_types.unscoped.entries
    end
    # subscription
    result = true if scan_subscriptions.current.try(:is_update_requested?)
    result
  end

  def set_request_type!
    if is_prescriber
      clients.active.each do |client|
        client.set_request_type
        client.save
      end
    elsif prescriber
      prescriber.set_request_type
      prescriber.save
    end
    set_request_type
    save
  end

  def set_request_type
    if self.is_new
      self.request_type = ADDING
    elsif is_update_requested?
      self.request_type = UPDATING
    else
      self.request_type = NOTHING
    end
  end

  def set_random_password
    new_password = rand(36**20).to_s(36)
    self.password = new_password
    self.password_confirmation = new_password
  end

protected

  def update_clients
    if self.client_ids != nil
      self.clients = User.any_in(_id: client_ids.split(','))
    else
      nil
    end
  end

  def set_inactive_at
    if self.is_inactive == "1"
      self.inactive_at = Time.now
    elsif self.is_inactive == "0"
      self.inactive_at = nil
    end
  end
  
  def format_name
    self.first_name = self.first_name.split.map(&:capitalize).join(" ") rescue ""
    self.last_name = self.last_name.upcase rescue ""
  end

  def set_timestamps_of_addresses
    self.addresses.each do |address|
      address.created_at ||= Time.now
      address.updated_at ||= Time.now
      address.save
    end
  end
end
