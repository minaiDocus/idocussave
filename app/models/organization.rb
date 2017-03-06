class Organization < ActiveRecord::Base
  attr_reader :member_tokens

  validates :authd_prev_period, numericality: { greater_than_or_equal_to: 0 }
  validates :auth_prev_period_until_day,   inclusion: { in: 0..28 }
  validates :auth_prev_period_until_month, inclusion: { in: 0..2 }
  validates_length_of     :code, in: 1..4
  validates_format_of     :code, with: /\A[A-Z0-9]*\z/
  validates_presence_of   :name, :code
  validates_uniqueness_of :name, :code


  has_one    :ibiza
  has_one    :knowings
  has_one    :subscription
  has_one    :csv_descriptor
  has_one    :file_sending_kit
  has_one    :file_naming_policy

  has_many   :packs
  has_many   :events
  has_many   :groups
  has_many   :orders
  has_many   :periods
  has_many   :reports,            class_name: 'Pack::Report'
  has_many   :members,            class_name: 'User',               inverse_of: 'organization'
  has_many   :expenses,           class_name: 'Pack::Report::Expense'
  has_many   :invoices
  has_many   :addresses, as: :locatable
  has_many   :temp_packs
  has_many   :preseizures,        class_name: 'Pack::Report::Preseizure'
  has_many   :pack_pieces, class_name: 'Pack::Piece', inverse_of: 'organization'
  has_many   :remote_files
  has_many   :temp_documents
  has_many   :paper_processes
  has_many   :reminder_emails,    autosave: true
  has_many   :period_documents
  has_many   :account_book_types
  has_many   :account_number_rules
  has_many   :pre_assignment_deliveries

  belongs_to :leader,             class_name: 'User',               inverse_of: 'my_organization'


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
    organization_ids = Invoice.where('created_at > ? AND created_at < ?', start_time, end_time).select(:organization_id).distinct.pluck(:organization_id)

    Organization.where("(is_test = ? AND is_active = ? AND is_for_admin = ?) OR (id IN (?) AND is_test = ? AND is_for_admin = ?)", false, true, false, organization_ids, false, false)
  end

  def to_param
    [id, name.parameterize].join('-')
  end

  def collaborators
    members.where(is_prescriber: true)
  end


  def customers
    members.where(is_prescriber: false)
  end


  def member_tokens=(ids)
    user_ids = ids.split(',')
    if (!members.empty? && !user_ids.empty?) || (members.empty? && user_ids.empty?)

      member_ids = members.map { |m| m.id.to_s }

      is_included = true

      member_ids.each do |id|
        is_included = false unless id.in?(user_ids)
      end

      if !is_included || user_ids.size != member_ids.size
        self.members = User.find(user_ids)
      end
    elsif !members.empty? && user_ids.empty?
      members.clear
    elsif members.empty? && !user_ids.empty?
      self.members = User.find(user_ids)
    end
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
    CsvDescriptor.create(organization_id: id)
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
    organizations = Organization.all.includes(:leader)

    organizations = organizations.where(is_active:    (contains[:is_active] == '1'))    unless contains[:is_active].blank?
    organizations = organizations.where(is_test:      (contains[:is_test] == '1'))      unless contains[:is_test].blank?
    organizations = organizations.where(created_at:   contains[:created_at])            unless contains[:created_at].blank?
    organizations = organizations.where(is_for_admin: (contains[:is_for_admin] == '1')) unless contains[:is_for_admin].blank?
    organizations = organizations.where(is_suspended: (contains[:is_suspended] == '1')) unless contains[:is_suspended].blank?

    if contains[:is_without_address].present?
      if contains[:is_without_address] == '1'
        organizations = organizations.where('addresses.is_for_billing' => { '$nin' => [true] })
      else
        organizations = organizations.where('addresses.is_for_billing' => true)
      end
    end

    if contains[:is_debit_mandate_not_configured].present?
      user_ids      = DebitMandate.configured.pluck(:user_id)
      leader_ids    = Organization.all.pluck(:leader_id)
      ids           = contains[:is_debit_mandate_not_configured] == '1' ? (leader_ids - user_ids) : user_ids
      organizations = organizations.where(leader_id: ids)
    end

    organizations = organizations.where("name LIKE ?", "%#{contains[:name]}%")               unless contains[:name].blank?
    organizations = organizations.where("description LIKE ?", "%#{contains[:description]}%") unless contains[:description].blank?

    organizations
  end
end
