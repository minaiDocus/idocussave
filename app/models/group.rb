class Group
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug
  include ActiveModel::ForbiddenAttributesProtection

  attr_reader :member_tokens, :customer_tokens
  attr_accessor :ensure_authorization

  field :name,        type: String
  field :description, type: String
  # Authorization
  field :is_add_authorized,     type: Boolean, default: true
  field :is_remove_authorized,  type: Boolean, default: true
  field :is_create_authorized,  type: Boolean, default: true
  field :is_edit_authorized,    type: Boolean, default: true
  field :is_destroy_authorized, type: Boolean, default: true

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

    #user_ids = ids.split(',')
    #if (self.members.size > 0 && user_ids.size > 0) || (self.members.size == 0 && user_ids.size == 0) || (self.members.size == 0 && user_ids.size > 0)
    #  member_ids = self.members.map { |m| m.id.to_s }
    #  is_included = member_ids.inject { |a, id| a && id.in?(user_ids) } || false
    #  if !is_included || user_ids.size != member_ids.size
    #    users = User.find(user_ids)
    #    add_users = users - self.members
    #    if add_users.count > 0 && @ensure_authorization && !self.is_add_authorized
    #      errors.add(:customer_tokens, I18n.t('authorization.unessessary_rights'))
    #    else
    #      add_users.each { |u| self.members << u }
    #    end
    #    sub_users = self.members - users
    #    if sub_users.count > 0 && @ensure_authorization && !self.is_remove_authorized
    #      errors.add(:customer_tokens, I18n.t('authorization.unessessary_rights'))
    #    else
    #      sub_users.each { |u| self.members.delete u }
    #    end
    #  end
    #elsif members.size > 0 && user_ids.size == 0
    #  self.members.clear
    #end
  end

  def customer_tokens=(ids)
    user_ids = ids.split(',')
    self.member_tokens = (user_ids + self.collaborators.map(&:_id)).uniq
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
