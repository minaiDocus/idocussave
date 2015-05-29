class AccountNumberRule
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :organization,                           inverse_of: 'members'
  has_and_belongs_to_many :users,	class_name: 'User', inverse_of: 'rules'

  field :name
  field :rule_type
  field :affect
  field :content
  field :third_party_account
  field :priority,            type: Integer, default: 0


  validates_presence_of :name
  validates_inclusion_of :rule_type, in: %w(truncate match)
  validates_inclusion_of :affect, in: %w(organization user)
  validates_presence_of :third_party_account, if: Proc.new { |r| r.rule_type == 'match' }
end
