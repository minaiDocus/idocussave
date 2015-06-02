class AccountNumberRule
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug

  belongs_to :organization
  has_and_belongs_to_many :users

  field :name
  field :rule_type
  field :affect
  field :content
  field :third_party_account
  field :priority,            type: Integer, default: 0

  slug :name

  validates_presence_of :name, :rule_type, :affect, :content, :priority
  validates_presence_of :third_party_account, if: Proc.new { |r| r.rule_type == 'match' }
  validates_inclusion_of :rule_type, in: %w(truncate match)
  validates_inclusion_of :affect, in: %w(organization user)
  validate :uniqueness_of_name

  scope :global,    -> { where(affect: 'organization') }
  scope :customers, -> { where(affect: 'user') }

  def name_pattern
    name.gsub(/\s+\(\d+\)\z/, '')
  end

  def similar_name
    organization.account_number_rules.where(name: /#{name_pattern}/)
  end

private

  def uniqueness_of_name
    rule = organization.account_number_rules.where(name: name).first
    errors.add(:name, :taken) if rule && rule != self
  end
end
