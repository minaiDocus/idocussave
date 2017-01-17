# -*- encoding : UTF-8 -*-
class User < ActiveRecord::Base
  devise :database_authenticatable, :recoverable, :rememberable, :validatable, :trackable, :lockable


  AUTHENTICATION_TOKEN_LENGTH = 20

  validate :format_of_code,      if: proc { |u| u.code_changed? }
  validate :belonging_of_parent, if: proc { |u| u.parent_id_changed? }
  validates :authd_prev_period,            numericality: { greater_than_or_equal_to: 0 }
  validates :auth_prev_period_until_day,   inclusion: { in: 0..28 }
  validates :auth_prev_period_until_month, inclusion: { in: 0..2 }
  validates_length_of :code, within: 3..15
  validates_length_of :email, maximum: 50
  validates_length_of :company, :first_name, :last_name, :knowings_code, within: 0..50, allow_nil: true
  validates_presence_of :email, :encrypted_password
  validates_presence_of :code
  validates_presence_of :company
  validates_inclusion_of :knowings_visibility, in: 0..2
  validates_inclusion_of :current_configuration_step, :last_configuration_step, in: %w(account subscription compta_options period_options journals ibiza use_csv_descriptor csv_descriptor accounting_plans vat_accounts exercises order_paper_set order_dematbox retrievers ged), allow_blank: true
  validates_uniqueness_of :code
  validates_uniqueness_of :email_code, unless: Proc.new { |u| u.is_prescriber }


  attr_accessor :is_group_required

  has_one :options, class_name: 'UserOptions', inverse_of: 'user', autosave: true
  has_one :dematbox
  has_one :composition
  has_one :subscription
  has_one :debit_mandate
  has_one :csv_descriptor, autosave: true
  has_one :accounting_plan
  has_one :my_organization, class_name: 'Organization', inverse_of: 'leader', foreign_key: :leader_id
  has_one :external_file_storage, autosave: true, dependent: :destroy


  has_many :packs, class_name: 'Pack', inverse_of: :owner, foreign_key: :owner_id
  has_many :orders
  has_many :events
  has_many :periods
  has_many :expenses, class_name: 'Pack::Report::Expense',    inverse_of: :user
  has_many :invoices
  has_many :children, class_name: 'User', inverse_of: :parent, foreign_key: :parent_id
  has_many :addresses, as: :locatable
  has_many :exercises
  has_many :temp_packs
  has_many :operations
  has_many :preseizures,  class_name: 'Pack::Report::Preseizure', inverse_of: :user
  has_many :pack_pieces,  class_name: 'Pack::Piece',              inverse_of: :user
  has_many :pack_reports, class_name: 'Pack::Report',             inverse_of: :user
  has_many :remote_files, dependent: :destroy
  has_many :sended_emails, class_name: 'Email',                    inverse_of: :from_user, dependent: :destroy, foreign_key: :from_user_id
  has_many :bank_accounts,                                                                      dependent: :destroy
  has_many :temp_documents
  has_many :paper_processes
  has_many :received_emails, class_name: 'Email',                    inverse_of: :to_user,   dependent: :destroy, foreign_key: :to_user_id
  has_many :period_documents
  has_many :account_book_types
  has_many :pre_assignment_deliveries

  belongs_to :parent,            class_name: 'User', inverse_of: :children
  belongs_to :organization,      inverse_of: 'members'
  belongs_to :scanning_provider, inverse_of: 'customers'

  has_one  :budgea_account,                                                                     dependent: :destroy
  has_many :retrievers,                                                                         dependent: :destroy
  has_many :retrieved_data,                                                                     dependent: :destroy
  has_many :new_provider_requests,                                                              dependent: :destroy
  has_many :sandbox_bank_accounts,                                                              dependent: :destroy
  has_many :sandbox_operations,                                                                 dependent: :destroy
  has_many :sandbox_documents,                                                                  dependent: :destroy


  has_and_belongs_to_many :groups, inverse_of: 'members'
  has_and_belongs_to_many :account_number_rules


  scope :active,                      -> { where(inactive_at: nil) }
  scope :closed,                      -> { where.not(inactive_at: [nil]) }
  scope :active_at,                   -> (time) { where(inactive_at: [nil]) }
  scope :operators,                   -> { where(is_operator: true) }
  scope :customers,                   -> { where(is_prescriber: false, is_operator: [false, nil]) }
  scope :prescribers,                 -> { where(is_prescriber: true) }
  scope :not_operators,               -> { where(is_operator: [false, nil]) }
  scope :fake_prescribers,            -> { where(is_prescriber: true, is_fake_prescriber: true) }
  scope :not_fake_prescribers,        -> { where(is_prescriber: true, is_fake_prescriber:  [false, nil]) }
  scope :dropbox_extended_authorized, -> { where(is_dropbox_extended_authorized: true) }


  accepts_nested_attributes_for :options
  accepts_nested_attributes_for :addresses, allow_destroy: true
  accepts_nested_attributes_for :csv_descriptor
  accepts_nested_attributes_for :external_file_storage


  before_validation do |user|
    if user.email_code.blank? && !user.is_prescriber
      user.email_code = user.get_new_email_code
    end
  end


  before_save do |user|
    user.format_name
  end


  def to_param
    "#{id}-#{first_name.gsub(" ", "-")}-#{last_name.gsub(" ", "-")}"
  end


  def name
    [first_name.presence, last_name.presence].compact.join(' ')
  end


  def username
    code
  end


  def username=(param)
    self.code = param
  end


  def info
    [code, company, name].reject(&:blank?).join(' - ')
  end


  def short_info
    [code, company].join(' - ')
  end


  def to_s
    info
  end


  def configured?
    current_configuration_step.nil?
  end


  # Do not keep this bad idea to override active_record methods for nothing
  def self.find_by_token(token)
    return nil unless token.is_a?(String) && token.size == AUTHENTICATION_TOKEN_LENGTH
    User.where(authentication_token: token).first
  end


  def active?
    !inactive?
  end


  def inactive?
    inactive_at.present?
  end


  def find_or_create_subscription
    self.subscription ||= Subscription.create(user_id: id)
  end


  def paper_return_address
    addresses.for_paper_return.first
  end


  def paper_set_shipping_address
    addresses.for_paper_set_shipping.first
  end


  def dematbox_shipping_address
    addresses.for_dematbox_shipping.first
  end


  def find_or_create_external_file_storage
    self.external_file_storage ||= ExternalFileStorage.create(user_id: id).reload
  end


  def csv_descriptor!
    self.csv_descriptor ||= CsvDescriptor.create(user_id: id)
  end


  def active_for_authentication?
    super && !is_disabled
  end


  def set_random_password
    new_password = rand(36**20).to_s(36)

    self.password              = new_password
    self.password_confirmation = new_password
  end


  def prescribers
    if !is_prescriber
      user_ids = []

      user_ids << organization.leader.id if organization.try(:leader)

      user_ids += User.where(group_ids: group_ids, is_prescriber: true).distinct(:id) if group_ids.present?

      if user_ids.any?
        User.where(id: user_ids).order(code: :asc)
      else
        []
      end
    else
      []
    end
  end


  def extend_organization_role
    if is_prescriber
      if my_organization
        extend OrganizationManagement::Leader
      elsif organization
        extend OrganizationManagement::Collaborator
      end
    end
  end


  def compta_processable_journals
    account_book_types.compta_processable
  end


  def is_return_label_generated_today?
    if return_label_generated_at
      return_label_generated_at > Time.now.beginning_of_day
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
    self.first_name = begin
                        first_name.split.map(&:capitalize).join(' ')
                      rescue
                        ''
                      end
    self.last_name = begin
                       last_name.upcase
                     rescue
                       ''
                     end
  end


  def active_for_authentication?
    super && (active? || (inactive_at + 18.months) > Time.now)
  end


  def recently_created?
    created_at > 24.hours.ago
  end


  def self.search(contains)
    users = User.not_operators

    users = contains[:is_inactive] == '1' ? users.closed : users.active                    if contains[:is_inactive].present?

    users = users.where("code LIKE ?",       "%#{contains[:code]}%")                           if contains[:code].present?
    users = users.where("email LIKE ?",      "%#{contains[:email]}%")                          if contains[:email].present?
    users = users.where("company LIKE ?",    "%#{contains[:company]}%")                        if contains[:company].present?
    users = users.where(is_admin:            (contains[:is_admin] == '1' ? true : false))      if contains[:is_admin].present?
    users = users.where(is_prescriber:       (contains[:is_prescriber] == '1' ? true : false)) if contains[:is_prescriber].present?
    users = users.where("last_name LIKE ?",  "%#{contains[:last_name]}%")                      if contains[:last_name].present?
    users = users.where(organization_id:     contains[:organization_id])                       if contains[:organization_id].present?
    users = users.where("first_name LIKE ?", "%#{contains[:first_name]}%")                     if contains[:first_name].present?


    if contains[:is_organization_admin].present?
      user_ids = Organization.all.pluck(:leader_id)

      users = if contains[:is_organization_admin] == '1'
                users.where(id: user_ids)
              else
                users.where.not(id: user_ids)
              end
    end

    users
  end


  def self.search_for_collection(collection, contains)
    collection = collection.where("code LIKE ?", "%#{contains[:code]}%") unless contains[:code].blank?
    collection = collection.where("email LIKE ?", "%#{contains[:email]}%") unless contains[:email].blank?
    collection = collection.where("company LIKE ?", "%#{contains[:company]}%") unless contains[:company].blank?
    collection = collection.where("last_name LIKE ?", "%#{contains[:last_name]}%") unless contains[:last_name].blank?
    collection = collection.where("first_name LIKE ?", "%#{contains[:first_name]}%") unless contains[:first_name].blank?

    collection = contains[:is_inactive] == '1' ? collection.closed : collection.active if contains[:is_inactive].present?

    collection
  end


  private


  def format_of_code
    if organization && !code.match(/\A#{organization.code}%[A-Z0-9]{1,13}\z/)
      errors.add(:code, :invalid)
    end
  end


  def belonging_of_parent
    unless parent.organization_id == organization_id
      errors.add(:parent_id, :invalid)
    end
  end
end
