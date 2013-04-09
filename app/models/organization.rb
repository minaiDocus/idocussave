class Organization
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug
  include ActiveModel::ForbiddenAttributesProtection

  attr_reader :member_tokens

  field :name,         type: String
  field :description,  type: String
  field :code,         type: String
  # Authorization
  field :is_detail_authorized,              type: Boolean, default: false
  field :is_period_duration_editable,       type: Boolean, default: true
  field :is_default_subscription_editable,  type: Boolean, default: true
  # Misc
  field :is_test, type: Boolean, default: false

  validates_presence_of :name, :leader_id
  validates_uniqueness_of :name
  validates_length_of :code, in: 2..4

  slug :name

  belongs_to :leader,             class_name: 'User',               inverse_of: 'my_organization'
  has_many   :members,            class_name: 'User',               inverse_of: 'organization'
  has_many   :groups
  has_many   :subscriptions
  has_many   :scan_subscriptions, class_name: 'Scan::Subscription', inverse_of: 'organization'
  has_many   :periods,            class_name: 'Scan::Period',       inverse_of: 'organization'
  has_many   :packs
  has_many   :invoices
  has_many   :account_book_types
  has_many   :reminder_emails,    autosave: true
  has_one    :file_sending_kit
  has_one    :ibiza
  has_one    :gray_label
  has_one    :csv_outputter, autosave: true

  embeds_many :addresses, as: :locatable

  accepts_nested_attributes_for :addresses,       allow_destroy: true
  accepts_nested_attributes_for :reminder_emails, allow_destroy: true
  accepts_nested_attributes_for :csv_outputter,   allow_destroy: true

  scope :not_test, where: { is_test: false }

  before_save :ensure_leader_is_member

  def collaborators
    members.where(is_prescriber: true)
  end

  def customers
    members.where(is_prescriber: false)
  end

  def decentralized_customers
    customers.not_in(_id: centralized_customers.map(&:_id))
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

  def find_or_create_file_sending_kit
    file_sending_kit || FileSendingKit.create(organization_id: self.id)
  end
  alias :foc_file_sending_kit :find_or_create_file_sending_kit

  def find_or_create_subscription
    if subscriptions.any?
      subscriptions.current
    else
      subscription = Scan::Subscription.new
      subscription.organization = self
      subscription.save
      subscription
    end
  end
  alias :foc_subscription :find_or_create_subscription
  alias :find_or_create_scan_subscription :find_or_create_subscription
  alias :foc_scan_subscription :find_or_create_subscription

  def find_or_create_csv_outputter
    csv_outputter || create_csv_outputter
  end
  alias :csv_outputter! :find_or_create_csv_outputter

  def create_csv_outputter
    CsvOutputter.create(organization_id: self.id)
  end

private

  def ensure_leader_is_member
    members << leader unless members.include?(leader)
  end
end
