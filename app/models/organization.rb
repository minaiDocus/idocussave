class Organization
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug

  attr_reader :member_tokens

  field :name,         type: String
  field :description,  type: String
  field :code,         type: String

  # Authorization
  field :is_detail_authorized,                  type: Boolean, default: false
  field :is_period_duration_editable,           type: Boolean, default: true
  field :is_journals_management_centralized,    type: Boolean, default: true
  field :is_subscription_lower_options_enabled, type: Boolean, default: false
  # Misc
  field :is_test,                         type: Boolean, default: false
  field :is_for_admin,                    type: Boolean, default: false
  field :is_active,                       type: Boolean, default: true
  field :is_suspended,                    type: Boolean, default: false
  field :is_quadratus_used,               type: Boolean, default: false
  field :is_pre_assignment_date_computed, type: Boolean, default: false
  field :is_csv_descriptor_used,          type: Boolean, default: false

  field :authd_prev_period,            type: Integer, default: 1
  field :auth_prev_period_until_day,   type: Integer, default: 11 # 0..31
  field :auth_prev_period_until_month, type: Integer, default: 0 # 0..3

  validates :authd_prev_period, numericality: { :greater_than_or_equal_to => 0 }
  validates :auth_prev_period_until_day,   inclusion: { in: 0..28 }
  validates :auth_prev_period_until_month, inclusion: { in: 0..2 }

  validates_presence_of :name, :code
  validates_uniqueness_of :name
  validates_length_of :code, in: 1..4
  validates_format_of :code, with: /\A[A-Z0-9]*\z/

  slug :name

  belongs_to :leader,             class_name: 'User',               inverse_of: 'my_organization'
  has_many   :members,            class_name: 'User',               inverse_of: 'organization'
  has_many   :groups
  has_many   :periods
  has_many   :period_documents
  has_many   :packs
  has_many   :pack_pieces,        class_name: 'Pack::Piece',        inverse_of: 'organization'
  has_many   :invoices
  has_many   :account_book_types
  has_many   :reminder_emails,    autosave: true
  has_many   :reports,            class_name: 'Pack::Report'
  has_many   :preseizures,        class_name: 'Pack::Report::Preseizure'
  has_many   :expenses,           class_name: 'Pack::Report::Expense'
  has_many   :remote_files
  has_many   :events
  has_many   :pre_assignment_deliveries
  has_many   :temp_packs
  has_many   :temp_documents
  has_many   :paper_processes
  has_many   :account_number_rules
  has_one    :subscription
  has_one    :file_sending_kit
  has_one    :ibiza
  has_one    :gray_label
  has_one    :csv_descriptor
  has_one    :knowings
  has_one    :file_naming_policy

  embeds_many :addresses, as: :locatable

  scope :not_billed,  -> { where('$or' => [{is_test: true}, {is_active: false}, {is_for_admin: true}]) }
  scope :billed,      -> { where(is_test: false, is_active: true, is_for_admin: false) }
  scope :suspended,   -> { where(is_suspended: true) }
  scope :unsuspended, -> { where(is_suspended: false) }
  scope :admin,       -> { where(is_for_admin: true) }
  scope :client,      -> { where(is_for_admin: false) }
  scope :active,      -> { where(is_active: true) }
  scope :inactive,    -> { where(is_active: false) }

  def collaborators
    members.where(is_prescriber: true)
  end

  def customers
    members.where(is_prescriber: false)
  end

  def member_tokens=(ids)
    user_ids = ids.split(',')
    if (members.size > 0 && user_ids.size > 0) || (members.size == 0 && user_ids.size == 0)
      member_ids = members.map { |m| m.id.to_s }
      is_included = true
      member_ids.each do |id|
        is_included = false unless id.in?(user_ids)
      end
      if !is_included || user_ids.size != member_ids.size
        self.members = User.find(user_ids)
      end
    elsif members.size > 0 && user_ids.size == 0
      self.members.clear
    elsif members.size == 0 && user_ids.size > 0
      self.members = User.find(user_ids)
    end
  end

  def to_s
    self.name
  end

  def info
    self.name
  end

  def find_or_create_file_sending_kit
    self.file_sending_kit ||= FileSendingKit.create(organization_id: self.id)
  end

  def find_or_create_subscription
    self.subscription ||= Subscription.create(organization_id: self.id)
  end

  def find_or_create_csv_descriptor
    self.csv_descriptor ||= create_csv_descriptor
  end
  alias :csv_descriptor! :find_or_create_csv_descriptor

  def find_or_create_file_naming_policy
    self.file_naming_policy ||= FileNamingPolicy.create(organization_id: self.id)
  end
  alias :foc_file_naming_policy :find_or_create_file_naming_policy

  def create_csv_descriptor
    CsvDescriptor.create(organization_id: self.id)
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

  def is_subscription_lower_options_disabled
    !is_subscription_lower_options_enabled
  end
end
