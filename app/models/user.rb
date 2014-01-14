# -*- encoding : UTF-8 -*-
class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::ForbiddenAttributesProtection
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
  field :is_fake_prescriber,             type: Boolean, default: false
  field :inactive_at,                    type: Time
  field :dropbox_delivery_folder,        type: String,  default: 'iDocus_delivery/:code/:year:month/:account_book/'
  field :is_dropbox_extended_authorized, type: Boolean, default: false
  field :file_type_to_deliver,           type: Integer, default: ExternalFileStorage::PDF
  field :is_reminder_email_active,       type: Boolean, default: true
  field :is_document_notifier_active,    type: Boolean, default: true
  field :is_centralized,                 type: Boolean, default: true

  validates_uniqueness_of :code

  field :is_disabled,                    type: Boolean, default: false
  field :is_editable,                    type: Boolean, default: true

  field :stamp_name,                     type: String,  default: ':code :account_book :period :piece_num'
  field :is_stamp_background_filled,     type: Boolean, default: false

  field :is_access_by_token_active,      type: Boolean, default: true
  field :is_inactive,                    type: Boolean, default: false

  field :is_dematbox_authorized,         type: Boolean, default: false

  field :return_label_generated_at, type: Time

  field :ibiza_id, type: String

  field :is_fiduceo_authorized, type: Boolean, default: false
  field :fiduceo_id

  field :authd_prev_period,            type: Integer, default: 1
  field :auth_prev_period_until_day,   type: Integer, default: 11 # 0..31
  field :auth_prev_period_until_month, type: Integer, default: 0 # 0..3

  validates :authd_prev_period, numericality: { :greater_than_or_equal_to => 0 }
  validates :auth_prev_period_until_day,   inclusion: { in: 0..28 }
  validates :auth_prev_period_until_month, inclusion: { in: 0..2 }

  attr_accessor :client_ids
  attr_protected :is_admin, :is_prescriber

  # FIXME use another way
  before_save :set_timestamps_of_addresses

  embeds_many :addresses, as: :locatable
  embeds_one :organization_rights

  has_one :my_organization, class_name: 'Organization', inverse_of: 'leader'
  belongs_to :organization, inverse_of: 'members'
  has_and_belongs_to_many :groups, inverse_of: 'members'

  has_one  :request,          as: :requestable,                              dependent: :destroy
  has_many :requests,                                inverse_of: :requester, dependent: :destroy

  has_many :periods,            class_name: "Scan::Period",       inverse_of: :user
  has_many :scan_subscriptions, class_name: "Scan::Subscription", inverse_of: :user
  
  has_many :own_packs, class_name: "Pack", inverse_of: :owner
  has_and_belongs_to_many :packs

  has_and_belongs_to_many :account_book_types,  inverse_of: :clients
  has_and_belongs_to_many :requested_account_book_types, class_name: 'AccountBookType', inverse_of: :requested_clients

  has_and_belongs_to_many :sharers, class_name: "User", inverse_of: :share_with
  has_and_belongs_to_many :share_with, class_name: "User", inverse_of: :sharers

  has_many :invoices
  has_many :credits
  has_many :subscriptions
  has_many :backups
  has_many :remote_files, dependent: :destroy
  has_many :log_visits, class_name: 'Log::Visit', inverse_of: :user
  has_many :pack_reports, class_name: 'Pack::Report', inverse_of: :user
  has_many :preseizures, class_name: 'Pack::Report::Preseizure', inverse_of: :user
  has_many :fiduceo_retrievers,   dependent: :destroy
  has_many :fiduceo_transactions, dependent: :destroy
  has_many :bank_accounts,        dependent: :destroy
  has_one :composition
  has_one :debit_mandate
  has_one :external_file_storage, autosave: true
  has_one :csv_outputter, autosave: true
  has_one :accounting_plan

  has_one :dematbox

  belongs_to :scanning_provider, inverse_of: 'customers'
  
  scope :prescribers,                 where: { is_prescriber: true }
  scope :fake_prescribers,            where: { is_prescriber: true, is_fake_prescriber: true }
  scope :not_fake_prescribers,        where: { is_prescriber: true, :is_fake_prescriber.in => [false, nil] }
  scope :dropbox_extended_authorized, where: { is_dropbox_extended_authorized: true }
  scope :active,                      where: { inactive_at: nil }
  scope :centralized,                 where: { is_centralized: true }
  scope :not_centralized,             where: { is_centralized: false }
  scope :active_at,                   lambda { |time| any_of({ :inactive_at.in => [nil] }, { :inactive_at.nin => [nil], :inactive_at.gt => time.end_of_month }) }
  scope :editable,                    where: { is_editable: true }

  before_save :format_name, :set_inactive_at

  accepts_nested_attributes_for :external_file_storage
  accepts_nested_attributes_for :addresses,             allow_destroy: true
  accepts_nested_attributes_for :csv_outputter
  accepts_nested_attributes_for :organization_rights

  def active
    inactive_at == nil
  end
  
  def name
    [self.first_name,self.last_name].join(' ') || self.email
  end

  def username
    self.code
  end

  def username=(param)
    self.code = param
  end

  def info
    [self.code,self.company,self.name].reject { |e| e.blank? }.join(' - ')
  end

  def to_s
    info
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
    !is_inactive?
  end
  
  def is_inactive?
    self.is_inactive
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

  def csv_outputter!
    csv_outputter || CsvOutputter.create(user_id: self.id)
  end

  def active_for_authentication?
    super && !self.is_disabled
  end

  def activate!
    request.accept!
    update_attribute(:is_disabled, false)
  end

  def set_random_password
    new_password = rand(36**20).to_s(36)
    self.password = new_password
    self.password_confirmation = new_password
  end

  def find_or_create_organization_rights
    organization_rights || create_organization_rights
  end

  def prescribers
    if !self.is_prescriber
      leader_id = organization.try(:leader_id)
      User.any_of({ :group_ids.in => self['group_ids'] }, { _id: leader_id }).prescribers.asc(:code)
    else
      []
    end
  end

  def extend_organization_role
    if self.is_prescriber
      if self.my_organization
        self.extend OrganizationManagement::Leader
      elsif self.organization
        self.extend OrganizationManagement::Collaborator
      end
    else
      nil
    end
  end

  def requestable_on
    [:email, :last_name, :first_name, :company, :code, :is_inactive, :is_centralized]
  end

  def request_status
    if request.status.present?
      request.status
    else
      find_or_create_scan_subscription.request_action
    end
  end

  def compta_processable_journals
    account_book_types.compta_processable
  end

  def is_return_label_generated_today?
    if self.return_label_generated_at
      self.return_label_generated_at > Time.now.beginning_of_day
    else
      false
    end
  end
  
protected

  def set_inactive_at
    if is_inactive? && self.inactive_at.presence.nil?
      self.inactive_at = Time.now
    elsif is_active?
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
