class Organization < ApplicationRecord
  validates :authd_prev_period, numericality: { greater_than_or_equal_to: 0 }
  validates :auth_prev_period_until_day,   inclusion: { in: 0..28 }
  validates :auth_prev_period_until_month, inclusion: { in: 0..2 }
  validates_length_of     :code, in: 1..4
  validates_format_of     :code, with: /\A[A-Z0-9]*\z/
  validates_presence_of   :name, :code
  validates_uniqueness_of :name, :code

  has_and_belongs_to_many :organization_groups, optional: true
  has_many :members
  has_many :admin_members, -> { admins }, class_name: 'Member'
  has_many :admins, through: :admin_members, source: :user
  has_many :collaborators, through: :members, source: :user
  has_many :customers, -> { customers }, class_name: 'User'
  has_many :guest_collaborators, -> { guest_collaborators }, class_name: 'User'
  has_many :users, -> { where(is_prescriber: false, is_operator: [false, nil]) }

  include OwnedSoftwares

  has_one  :knowings
  has_one  :subscription
  has_one  :file_sending_kit
  has_one  :file_naming_policy
  has_one  :debit_mandate, dependent: :destroy
  has_one  :ftp
  has_one  :sftp
  has_one  :mcf_settings, dependent: :destroy
  has_many :packs
  has_many :events
  has_many :groups
  has_many :orders
  has_many :periods
  has_many :reports, class_name: 'Pack::Report'
  has_many :expenses, class_name: 'Pack::Report::Expense'
  has_many :invoices
  has_many :invoice_settings
  has_many :addresses, as: :locatable
  has_many :temp_packs
  has_many :preseizures, class_name: 'Pack::Report::Preseizure'
  has_many :temp_preseizures,  class_name: 'Pack::Report::TempPreseizure'
  has_many :pack_pieces, class_name: 'Pack::Piece', inverse_of: 'organization'
  has_many :remote_files
  has_many :temp_documents
  has_many :paper_processes
  has_many :reminder_emails, autosave: true
  has_many :period_documents
  has_many :account_book_types
  has_many :account_number_rules
  has_many :pre_assignment_deliveries
  has_many :pre_assignment_exports
  has_many :account_sharings

  accepts_nested_attributes_for :ibiza
  accepts_nested_attributes_for :coala
  accepts_nested_attributes_for :quadratus
  accepts_nested_attributes_for :fec_acd
  accepts_nested_attributes_for :fec_agiris
  accepts_nested_attributes_for :cegid
  accepts_nested_attributes_for :exact_online
  accepts_nested_attributes_for :my_unisoft
  accepts_nested_attributes_for :csv_descriptor

  scope :admin,       -> { where(is_for_admin: true) }
  scope :active,      -> { where(is_active: true) }
  scope :billed,      -> { where(is_test: false, is_active: true, is_for_admin: false) }
  scope :client,      -> { where(is_for_admin: false) }
  scope :inactive,    -> { where(is_active: false) }
  scope :suspended,   -> { where(is_suspended: true) }
  scope :not_billed,  -> { where("is_test = ? OR is_active = ? OR is_for_admin = ?", true, false, true) }
  scope :unsuspended, -> { where(is_suspended: false) }

  def self.billed_for_year(year)
    start_time = Time.local(year).beginning_of_year + 15.days
    end_time   = Time.local(year).end_of_year + 15.days
    organization_ids = Invoice.where('created_at > ? AND created_at < ?', start_time, end_time).distinct.pluck(:organization_id)

    Organization.where("(is_test = ? AND is_active = ? AND is_for_admin = ?) OR (id IN (?) AND is_test = ? AND is_for_admin = ?)", false, true, false, organization_ids, false, false)
  end

  def to_param
    [id, name.parameterize].join('-')
  end

  def to_s
    name
  end

  def info
    name
  end

  def active?
    is_active
  end

  def inactive?
    !is_active
  end

  def find_or_create_file_sending_kit
    self.file_sending_kit ||= FileSendingKit.create(organization_id: id)
  end

  def find_or_create_subscription
    self.subscription ||= Subscription.create(organization_id: id)
  end

  def find_or_create_csv_descriptor
    self.csv_descriptor ||= create_csv_descriptor
  end
  alias csv_descriptor! find_or_create_csv_descriptor

  def find_or_create_file_naming_policy
    self.file_naming_policy ||= FileNamingPolicy.create(organization_id: id)
  end
  alias foc_file_naming_policy find_or_create_file_naming_policy

  def create_csv_descriptor
    Software::CsvDescriptor.create(owner_id: id)
  end

  def billing_address
    addresses.for_billing.first
  end

  def paper_return_address
    addresses.for_paper_return.first
  end

  def paper_set_shipping_address
    addresses.for_paper_set_shipping.first
  end

  def self.search(contains)
    organizations = Organization.all
    organizations = organizations.where(is_active:    (contains[:is_active] == '1'))    unless contains[:is_active].blank?
    organizations = organizations.where(is_test:      (contains[:is_test] == '1'))      unless contains[:is_test].blank?

    contains[:created_at].each { |compare,date| organizations = organizations.where("organizations.created_at #{compare} ? ", "#{date}")} unless contains[:created_at].blank?

    organizations = organizations.where(is_for_admin: (contains[:is_for_admin] == '1')) unless contains[:is_for_admin].blank?
    organizations = organizations.where(is_suspended: (contains[:is_suspended] == '1')) unless contains[:is_suspended].blank?

    if contains[:is_without_address].present?
      org_ids = Address.where(is_for_billing: true, locatable_type: 'Organization').select('locatable_id').distinct

      if contains[:is_without_address] == '1'
        organizations = organizations.where.not(id: org_ids)
      else
        organizations = organizations.where(id: org_ids)
      end
    end

    if contains[:is_debit_mandate_not_configured].present?
      if contains[:is_debit_mandate_not_configured] == '1'
        organizations = organizations.where.not(id: DebitMandate.configured.pluck(:organization_id))
      else
        organizations = organizations.where(id: DebitMandate.configured.pluck(:organization_id))
      end
    end

    organizations = organizations.where("code LIKE ?", "%#{contains[:code]}%")               if contains[:code].present?
    organizations = organizations.where("name LIKE ?", "%#{contains[:name]}%")               unless contains[:name].blank?
    organizations = organizations.where("description LIKE ?", "%#{contains[:description]}%") unless contains[:description].blank?

    organizations
  end

  def get_preseizure_date_option
    UserOptions::PRESEIZURE_DATE_OPTIONS[preseizure_date_option]
  end

  def uses_softwares?
    uses_api_softwares? || uses_non_api_softwares?
  end

  def uses_api_softwares?
    exact_online.try(:used?) || ibiza.try(:configured?) || my_unisoft.try(:used?)
  end

  def uses_non_api_softwares?
    coala.try(:used?) || quadratus.try(:used?) || cegid.try(:used?) || csv_descriptor.try(:used?) || fec_agiris.try(:used?) || fec_acd.try(:used?)
  end

  def auto_deliver?(_software)
    @software = _software

    self.try(software.to_sym).auto_deliver == 1
  end

  def banking_provider
    default_banking_provider ? default_banking_provider : 'budget_insight'
  end

  def compta_analysis_activated?(_software)
    @software = _software

    self.try(software.to_sym).is_analysis_activated == 1
  end

  def analysis_to_validate?(_software)
    @software = _software

    self.try(software.to_sym).is_analysis_to_validate == 1
  end

  def get_associated_organization(oid)
    organization_groups.each do |organization_group|
      return organization_group.get_organization(oid) if organization_group.belong_to?(oid)
    end
  end

  def belongs_to_groups?
    organization_groups.map {|organization_group| organization_group.multi_organizations?}.uniq.include?(true)
  end

  private

  def software
    if Interfaces::Software::Configuration::SOFTWARES_OBJECTS.include?(@software) || @software.is_a?(ActiveRecord::Base)
      @software = @software.to_s.split('<')[1].split(':0x')[0]
      @software = Interfaces::Software::Configuration.software_object_name[@software]
    end

    @software
  end
end
