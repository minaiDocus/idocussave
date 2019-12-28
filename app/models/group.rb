class Group < ApplicationRecord
  belongs_to :organization
  has_and_belongs_to_many :members
  has_many :collaborators, through: :members, source: :user
  has_and_belongs_to_many :customers, -> { customers }, class_name: 'User'
  has_many :remote_files

  # TODO : remove this after migration
  has_and_belongs_to_many :users

  validate :uniqueness_of_name
  validates_presence_of :name, :organization_id

  def info
    name
  end

  def to_s
    name
  end

  def self.search(contains)
    groups = self.all
    groups = groups.where("name LIKE ?",        "%#{contains[:name]}%")        unless contains[:name].blank?
    groups = groups.where("description LIKE ?", "%#{contains[:description]}%") unless contains[:description].blank?
    groups
  end

  private

  def uniqueness_of_name
    if (group = organization.groups.where(name: name).first)
      errors.add(:name, :taken) if group != self
    end
  end
end
