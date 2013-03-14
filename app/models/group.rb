class Group
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug
  include ActiveModel::ForbiddenAttributesProtection

  attr_reader :member_tokens, :customer_tokens

  field :name,        type: String
  field :description, type: String

  validates_presence_of :name, :organization_id
  validate :uniqueness_of_name

  slug :name

  belongs_to :organization
  has_and_belongs_to_many :members, class_name: 'User', inverse_of: 'groups'

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
    end
  end

  def customer_tokens=(ids)
    self.member_tokens = [ids, self.collaborators.map(&:_id).join(',')].join(',')
  end

  def to_s
    self.name
  end

private

  def uniqueness_of_name
    if(group = self.organization.groups.where(name: self.name).first)
      errors.add(:name, :already_taken, group) if group != self
    end
  end
end
