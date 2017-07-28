class Group < ActiveRecord::Base
  attr_reader :member_tokens, :customer_tokens

  validate :uniqueness_of_name
  validates_presence_of :name, :organization_id


  has_many :remote_files

  belongs_to :organization

  has_and_belongs_to_many :members, class_name: 'User', inverse_of: 'groups'

  def info
    name
  end


  def collaborators
    members.prescribers
  end

  def customers
    members.customers
  end


  def member_tokens=(user_ids)
    _user_ids = user_ids.map(&:to_s)
    member_ids = members.map { |m| m.id.to_s }

    if _user_ids.sort != member_ids.sort
      members.clear

      User.find(_user_ids).each do |user|
        members << user

        user.save unless persisted?
      end
    end
  end


  def customer_tokens=(ids)
    self.member_tokens = ids + collaborators.map(&:id)
  end


  def to_s
    name
  end


  def self.search_for_collection(collection, contains)
    collection = collection.where("name LIKE ?",        "%#{contains[:name]}%")        unless contains[:name].blank?
    collection = collection.where("description LIKE ?", "%#{contains[:description]}%") unless contains[:description].blank?
    collection
  end

  private


  def uniqueness_of_name
    if (group = organization.groups.where(name: name).first)
      errors.add(:name, :taken) if group != self
    end
  end
end
