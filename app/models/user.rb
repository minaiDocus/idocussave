# -*- encoding : UTF-8 -*-
class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug
  devise :database_authenticatable, :recoverable, :rememberable, :validatable, :trackable, :lockable

  AUTHENTICATION_TOKEN_LENGTH = 20

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

  ## Lockable
  field :failed_attempts, type: Integer, default: 0 # Only if lock strategy is :failed_attempts
  field :unlock_token,    type: String # Only if unlock strategy is :email or :both
  field :locked_at,       type: Time

  field :authentication_token

  field :is_admin,                       type: Boolean, default: false
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
  field :is_operator,                    type: Boolean

  validates_presence_of :code
  validates_length_of :code, within: 3..15
  validate :format_of_code, if: Proc.new { |u| u.code_changed? }
  validates_uniqueness_of :code

  validates_presence_of :company
  validates_length_of :email, :company, :first_name, :last_name, within: 0..50
  validates_length_of :knowings_code, within: 0..50, if: Proc.new { |u| u.knowings_code.present? }

  validate :presence_of_group, if: Proc.new { |u| u.is_group_required }

  field :knowings_code
  field :knowings_visibility,            type: Integer, default: 0

  validates_inclusion_of :knowings_visibility, in: 0..2

  field :is_disabled,                    type: Boolean, default: false

  field :stamp_name,                     type: String,  default: ':code :account_book :period :piece_num'
  field :is_stamp_background_filled,     type: Boolean, default: false

  field :is_access_by_token_active,      type: Boolean, default: true

  field :is_dematbox_authorized,         type: Boolean, default: false

  field :return_label_generated_at, type: Time

  field :ibiza_id, type: String

  field :is_fiduceo_authorized, type: Boolean, default: false
  field :fiduceo_id

  field :email_code
  field :is_mail_receipt_activated, type: Boolean, default: true

  validates_uniqueness_of :email_code, :unless => Proc.new { |u| u.is_prescriber }

  field :authd_prev_period,            type: Integer, default: 1
  field :auth_prev_period_until_day,   type: Integer, default: 11 # 0..31
  field :auth_prev_period_until_month, type: Integer, default: 0 # 0..3

  validates :authd_prev_period, numericality: { :greater_than_or_equal_to => 0 }
  validates :auth_prev_period_until_day,   inclusion: { in: 0..28 }
  validates :auth_prev_period_until_month, inclusion: { in: 0..2 }

  attr_accessor :is_group_required

  slug do |user|
    user.code.gsub(/(#|%)/, ' ').to_url
  end

  embeds_many :addresses, as: :locatable
  embeds_one :organization_rights

  has_one :my_organization, class_name: 'Organization', inverse_of: 'leader'
  belongs_to :organization, inverse_of: 'members'
  has_and_belongs_to_many :groups, inverse_of: 'members'

  has_many :periods
  has_many :period_documents
  has_many :packs,              class_name: "Pack",                     inverse_of: :owner
  has_many :pack_pieces,        class_name: "Pack::Piece",              inverse_of: :user
  has_many :account_book_types
  has_many :invoices
  has_many :remote_files,                                                                       dependent: :destroy
  has_many :events
  has_many :pack_reports,       class_name: 'Pack::Report',             inverse_of: :user
  has_many :preseizures,        class_name: 'Pack::Report::Preseizure', inverse_of: :user
  has_many :expenses,           class_name: 'Pack::Report::Expense',    inverse_of: :user
  has_many :temp_packs
  has_many :temp_documents
  has_many :fiduceo_retrievers,                                                                 dependent: :destroy
  has_many :fiduceo_transactions,                                                               dependent: :destroy
  has_many :fiduceo_provider_wishes,                                                            dependent: :destroy
  has_many :bank_accounts,                                                                      dependent: :destroy
  has_many :exercices
  has_many :sended_emails,      class_name: 'Email',                    inverse_of: :from_user, dependent: :destroy
  has_many :received_emails,    class_name: 'Email',                    inverse_of: :to_user,   dependent: :destroy
  has_many :operations
  has_many :pre_assignment_deliveries
  has_many :paper_processes
  has_one :subscription
  has_one :composition
  has_one :debit_mandate
  has_one :external_file_storage,                                               autosave: true, dependent: :destroy
  has_one :csv_outputter,                                                                       autosave: true
  has_one :accounting_plan
  has_one :options,             class_name: 'UserOptions',              inverse_of: 'user',     autosave: true
  has_one :dematbox

  belongs_to :scanning_provider, inverse_of: 'customers'

  scope :prescribers,                 -> { where(is_prescriber: true) }
  scope :fake_prescribers,            -> { where(is_prescriber: true, is_fake_prescriber: true) }
  scope :not_fake_prescribers,        -> { where(is_prescriber: true, :is_fake_prescriber.in => [false, nil]) }
  scope :customers,                   -> { where(is_prescriber: false, :is_operator.in => [false, nil]) }
  scope :operators,                   -> { where(is_operator: true) }
  scope :not_operators,               -> { where(:is_operator.in => [false, nil]) }
  scope :dropbox_extended_authorized, -> { where(is_dropbox_extended_authorized: true) }
  scope :active,                      -> { where(inactive_at: nil) }
  scope :closed,                      -> { where(:inactive_at.nin => [nil]) }
  scope :centralized,                 -> { where(is_centralized: true) }
  scope :not_centralized,             -> { where(is_centralized: false) }
  scope :active_at,                   -> time { any_of({ :inactive_at.in => [nil] }, { :inactive_at.nin => [nil], :inactive_at.gt => time.end_of_month }) }

  accepts_nested_attributes_for :external_file_storage
  accepts_nested_attributes_for :addresses,             allow_destroy: true
  accepts_nested_attributes_for :csv_outputter
  accepts_nested_attributes_for :organization_rights
  accepts_nested_attributes_for :options

  before_validation do |user|
    if user.email_code.blank? && !user.is_prescriber
      user.email_code = user.get_new_email_code
    end
  end

  before_save do |user|
    # FIXME use another way
    user.set_timestamps_of_addresses
    user.format_name
  end

  before_destroy do |user|
    FiduceoUser.new(user, false).destroy if user.fiduceo_id.present?
  end

  def name
    [first_name.presence, last_name.presence].compact.join(' ')
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

  def short_info
    [self.code, self.company].join(' - ')
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

  def self.find_by_token(token)
    return nil unless token.is_a?(String) && token.size == AUTHENTICATION_TOKEN_LENGTH
    User.where(authentication_token: token).first
  end

  def is_subscribed_to_category(number)
    if self.subscriptions.where(category: number).first
      true
    else
      false
    end
  end

  def active?
    !inactive?
  end

  def inactive?
    self.inactive_at.present?
  end

  def find_or_create_subscription
    self.subscription ||= Subscription.create(user_id: self.id)
  end

  def billing_address
    self.addresses.for_billing.first
  end

  def shipping_address
    self.addresses.for_shipping.first
  end

  def kit_shipping_address
    self.addresses.for_kit_shipping.first
  end

  def find_or_create_external_file_storage
    self.external_file_storage ||= ExternalFileStorage.create(user_id: self.id).reload
  end

  def find_or_create_efs
    find_or_create_external_file_storage
  end

  def csv_outputter!
    self.csv_outputter ||= CsvOutputter.create(user_id: self.id)
  end

  def active_for_authentication?
    super && !self.is_disabled
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
    if !is_prescriber
      user_ids = []
      user_ids << organization.leader.id if organization.try(:leader)
      user_ids += User.where(:group_ids.in => group_ids, is_prescriber: true).distinct(:_id) if group_ids.present?
      if user_ids.any?
        User.where(:_id.in => user_ids).asc(:code)
      else
        []
      end
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

  def get_new_email_code
    begin
      new_email_code = rand(36**8).to_s(36)
    end while self.class.where(email_code: new_email_code).first
    new_email_code
  end

  def update_email_code
    update_attribute(:email_code, get_new_email_code)
  end

  def get_new_authentication_token
    begin
      new_authentication_token = rand(36**AUTHENTICATION_TOKEN_LENGTH).to_s(36)
    end while self.class.where(authentication_token: new_authentication_token).first
    new_authentication_token
  end

  def update_authentication_token
    update_attribute(:authentication_token, get_new_authentication_token)
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

  def active_for_authentication?
    super && (active? || (inactive_at + 18.months) > Time.now)
  end

private

  def format_of_code
    if self.organization && !self.code.match(/^#{self.organization.code}%[A-Z0-9]{1,13}$/)
      errors.add(:code, :invalid)
    end
  end

  def presence_of_group
    errors.add(:group_ids, :empty) if groups.count == 0
  end
end
