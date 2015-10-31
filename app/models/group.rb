class Group
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug

  attr_reader :member_tokens, :customer_tokens

  field :name,        type: String
  field :description, type: String

  # Dropbox Extended
  field :dropbox_delivery_folder, type: String,  default: 'iDocus_delivery/:code/:year:month/:account_book/'
  field :is_dropbox_authorized,   type: Boolean, default: false

  validates_presence_of :name, :organization_id
  validate :uniqueness_of_name

  slug :name

  belongs_to :organization
  has_and_belongs_to_many :members, class_name: 'User', inverse_of: 'groups'
  has_many :remote_files

  def info
    name
  end

  def collaborators
    members.where(is_prescriber: true)
  end

  def customers
    members.where(is_prescriber: false)
  end

  def member_tokens=(user_ids)
    member_ids = members.map { |m| m.id.to_s }
    if user_ids.sort != member_ids.sort
      members.clear
      User.find(user_ids).each do |user|
        members << user
        user.timeless.save unless persisted?
      end
    end
  end

  def customer_tokens=(ids)
    self.member_tokens = ids + self.collaborators.map(&:_id)
  end

  def to_s
    self.name
  end

private

  def uniqueness_of_name
    if(group = self.organization.groups.where(name: self.name).first)
      errors.add(:name, :taken) if group != self
    end
  end
end
