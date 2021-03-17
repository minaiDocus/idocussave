class User < ApplicationRecord
  include ::CodeFormatValidation
  include Interfaces::User::Customer
  include Interfaces::User::Collaborator

  devise :database_authenticatable, :recoverable, :rememberable, :validatable, :trackable, :lockable

  AUTHENTICATION_TOKEN_LENGTH = 20

  validate :belonging_of_manager, if: proc { |u| u.manager_id_changed? && u.manager_id.present? }
  validates :authd_prev_period,            inclusion: { in: 0..36 }
  validates :auth_prev_period_until_day,   inclusion: { in: 0..28 }
  validates :auth_prev_period_until_month, inclusion: { in: 0..2 }
  validates_length_of :code, within: 3..15, unless: Proc.new { |u| u.collaborator? || u.is_guest }
  validates_length_of :email, maximum: 50
  validates_length_of :company, :first_name, :last_name, :knowings_code, within: 0..50, allow_nil: true
  validates_presence_of :email, :encrypted_password
  validates_presence_of :code, unless: Proc.new { |u| u.collaborator? || u.is_guest }
  validates_presence_of :company
  validates_inclusion_of :knowings_visibility, in: 0..2
  validates_inclusion_of :current_configuration_step, :last_configuration_step, in: %w(account subscription softwares_selection compta_options period_options journals ibiza use_csv_descriptor csv_descriptor accounting_plans vat_accounts exercises order_paper_set order_dematbox retrievers ged), allow_blank: true
  validates_uniqueness_of :code, unless: Proc.new { |u| u.collaborator? || u.is_guest }
  validates_uniqueness_of :email_code, unless: Proc.new { |u| u.is_prescriber }
  validate :presence_of_group, if: Proc.new { |u| u.is_group_required }
  validate :belonging_of_groups, if: Proc.new { |u| u.group_ids_changed? }

  attr_accessor :is_group_required

  has_many :memberships, class_name: 'Member', foreign_key: :user_id, dependent: :destroy
  has_many :organizations, through: :memberships

  has_one :options, class_name: 'UserOptions', inverse_of: 'user', autosave: true

  include OwnedSoftwares

  has_one :dematbox
  has_one :composition
  has_one :subscription
  has_one :accounting_plan
  has_one :external_file_storage, autosave: true, dependent: :destroy
  has_one :notify, dependent: :destroy
  has_one :invoice_settings

  has_many :packs, class_name: 'Pack', inverse_of: :owner, foreign_key: :owner_id
  has_many :orders
  has_many :events
  has_many :periods
  has_many :expenses, class_name: 'Pack::Report::Expense',    inverse_of: :user
  has_many :invoices
  has_many :addresses, as: :locatable
  has_many :exercises
  has_many :temp_packs
  has_many :operations
  has_many :forced_processing_operations, class_name: 'Operation', foreign_key: :forced_processing_by_user_id, inverse_of: :forced_processing_by_user
  has_many :preseizures,  class_name: 'Pack::Report::Preseizure', inverse_of: :user
  has_many :pack_pieces,  class_name: 'Pack::Piece',              inverse_of: :user
  has_many :pack_reports, class_name: 'Pack::Report',             inverse_of: :user
  has_many :remote_files
  has_many :sended_emails, class_name: 'Email',                    inverse_of: :from_user, dependent: :destroy, foreign_key: :from_user_id
  has_many :bank_accounts,                                                                      dependent: :destroy
  has_many :temp_documents
  has_many :paper_processes
  has_many :received_emails, class_name: 'Email',                    inverse_of: :to_user,   dependent: :destroy, foreign_key: :to_user_id
  has_many :period_documents
  has_many :account_book_types
  has_many :pre_assignment_deliveries
  has_many :pre_assignment_exports
  has_many :notifications, dependent: :destroy
  has_many :ibizabox_folders, dependent: :destroy

  belongs_to :manager, class_name: 'Member', inverse_of: :managed_users, optional: true

  belongs_to :organization,      inverse_of: 'members', optional: true
  belongs_to :scanning_provider, inverse_of: 'customers', optional: true

  has_one  :budgea_account,                                                                     dependent: :destroy
  has_one  :bridge_account,                                                                     dependent: :destroy
  has_many :retrievers,                                                                         dependent: :destroy
  has_many :retrievers_historics,                                                               dependent: :destroy
  has_many :retrieved_data,                                                                     dependent: :destroy
  has_many :new_provider_requests,                                                              dependent: :destroy
  has_many :firebase_tokens,                                                                    dependent: :destroy
  has_many :mobile_connexions,                                                                  dependent: :destroy
  has_many :mcf_documents,                                                                      dependent: :destroy

  has_and_belongs_to_many :groups, inverse_of: 'members'
  has_and_belongs_to_many :account_number_rules

  has_many :authorized_account_sharings, class_name: 'AccountSharing', inverse_of: 'authorized_by', foreign_key: 'authorized_by_id'

  has_many :account_sharings, foreign_key: 'collaborator_id', dependent: :destroy
  has_many :accounts, -> { distinct }, class_name: 'User', through: :account_sharings
  has_many :inverse_account_sharings, class_name: 'AccountSharing', foreign_key: 'account_id', dependent: :destroy
  has_many :collaborators, -> { distinct }, class_name: 'User', through: :inverse_account_sharings, source: :collaborator

  scope :active,                      -> { where(inactive_at: nil) }
  scope :closed,                      -> { where.not(inactive_at: [nil]) }
  scope :active_at,                   -> (time) { where('inactive_at IS NULL OR inactive_at > ?', time.end_of_month) }
  scope :operators,                   -> { where(is_operator: true) }
  scope :customers,                   -> { where(is_prescriber: false, is_operator: [false, nil], is_guest: false) }
  scope :prescribers,                 -> { where(is_prescriber: true) }
  scope :not_operators,               -> { where(is_operator: [false, nil]) }
  scope :fake_prescribers,            -> { where(is_prescriber: true, is_fake_prescriber: true) }
  scope :not_fake_prescribers,        -> { where(is_prescriber: true, is_fake_prescriber:  [false, nil]) }
  scope :dropbox_extended_authorized, -> { where(is_dropbox_extended_authorized: true) }
  scope :guest_collaborators,         -> { where(is_prescriber: false, is_guest: true) }

  accepts_nested_attributes_for :options
  accepts_nested_attributes_for :ibiza
  accepts_nested_attributes_for :coala
  accepts_nested_attributes_for :quadratus
  accepts_nested_attributes_for :fec_agiris
  accepts_nested_attributes_for :cegid
  accepts_nested_attributes_for :exact_online
  accepts_nested_attributes_for :my_unisoft
  accepts_nested_attributes_for :addresses, allow_destroy: true
  accepts_nested_attributes_for :csv_descriptor
  accepts_nested_attributes_for :external_file_storage
  accepts_nested_attributes_for :notify

  before_validation do |user|
    if user.email_code.blank? && !user.is_prescriber
      user.email_code = user.get_new_email_code
    end
  end

  before_save do |user|
    user.format_name
  end

  def self.using_by_software(software)
    if software.in? Interfaces::Software::Configuration::SOFTWARES
      self.all.joins(software.to_sym).where("#{Interfaces::Software::Configuration.softwares_table_name[software.to_sym]}".to_sym => { is_used: true } )
    end
  end

  def self.filter_by_software(software=nil)
    response = self.all

    response.map do |user|
      next if user.collaborator?

      case software
        when 'ibiza'
          skip_user = user.uses?(:exact_online) || user.uses?(:my_unisoft)
        when 'exact_online'
          skip_user = user.uses?(:ibiza) || user.uses?(:my_unisoft)
        when 'my_unisoft'
          skip_user = user.uses?(:ibiza) || user.uses?(:exact_online)
        else
          skip_user = false
      end

      next if skip_user
      user
    end
  end

  #login can be email or code
  def self.find_by_mail_or_code(login)
    user = self.find_by_email login
    user ||= self.get_by_code login
  end

  # Do not keep this bad idea to override active_record methods for nothing
  def self.find_by_token(token)
    return nil unless token.is_a?(String)
    User.where(authentication_token: token).first
  end

  # TODO : need a test
  def self.search(contains)
    users = self.all

    if contains[:collaborator_id].present?
      collaborator = User.unscoped.find(contains[:collaborator_id].to_i) rescue nil
      if collaborator
        collaborator = Collaborator.new(collaborator)
        groups = collaborator.groups
        customers = groups.map{ |g| g.customers.pluck(:id) }.compact.flatten || [0]
        users = users.where(id: customers)
      end
    end

    if contains[:group_ids].present?
      groups = Group.find(contains[:group_ids]) rescue nil
      if groups
        customers = groups.map{ |g| g.customers.pluck(:id) }.compact.flatten || [0]
        users = users.where(id: customers)
      end
    end

    users = contains[:is_inactive] == '1' ? users.closed : users.active                        if contains[:is_inactive].present?
    users = users.where(is_admin:            (contains[:is_admin] == '1' ? true : false))      if contains[:is_admin].present?
    users = users.where(is_prescriber:       (contains[:is_prescriber] == '1' ? true : false)) if contains[:is_prescriber].present?
    users = users.where(is_guest:            (contains[:is_guest] == '1' ? true : false))      if contains[:is_guest].present?
    users = users.where(organization_id:     contains[:organization_id])                       if contains[:organization_id].present?

    users = users.where("code LIKE ?",       "%#{contains[:code]}%")                           if contains[:code].present?
    users = users.where("email LIKE ?",      "%#{contains[:email]}%")                          if contains[:email].present?
    users = users.where("company LIKE ?",    "%#{contains[:company]}%")                        if contains[:company].present?
    users = users.where("last_name LIKE ?",  "%#{contains[:last_name]}%")                      if contains[:last_name].present?
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

  def self.get_by_code(code)
    member = Member.find_by_code(code)

    return member.user if member
    return User.find_by_code(code)
  end

  #Overwrite User code method
  def my_code
    self.code.presence || self.memberships.first.try(:code)
  end

  def to_param
    [id, company.parameterize].join('-')
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
    [(is_guest ? email : code), company, name].reject(&:blank?).join(' - ')
  end


  def short_info
    [code, company].join(' - ')
  end


  def to_s
    info
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
    self.external_file_storage ||= ExternalFileStorage.create(user_id: id)
  end


  def csv_descriptor!
    self.csv_descriptor ||= Software::CsvDescriptor.create(owner_id: id)
  end


  def active_for_authentication?
    super && !is_disabled
  end

  def set_random_password
    new_password = rand(36**20).to_s(36)

    self.password              = new_password
    self.password_confirmation = new_password
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

  def get_authentication_token
    update_authentication_token unless self.authentication_token.present?
    self.reload.authentication_token
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
    self.first_name = (first_name.split.map(&:capitalize).join(' ') rescue '')
    self.last_name = (last_name.upcase rescue '')
  end


  def active_for_authentication?
    super && (active? || (inactive_at + 18.months) > Time.now)
  end

  def recently_created?
    created_at > 24.hours.ago
  end

  private

  def belonging_of_manager
    unless manager.organization_id == organization_id
      errors.add(:manager_id, :invalid)
    end
  end

  def presence_of_group
    errors.add(:group_ids, :empty) if groups.empty?
  end

  def belonging_of_groups
    self.groups.each do |group|
      unless group.organization_id == self.organization_id
        errors.add(:group_ids, :invalid)
      end
    end
  end
end