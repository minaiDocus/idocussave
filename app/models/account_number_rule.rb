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

  scope :global,    -> { where(affect: 'organization') }
  scope :customers, -> { where(affect: 'user') }
end
