class OrganizationGroup < ApplicationRecord
  has_and_belongs_to_many :organizations

  validates :name, presence: true, uniqueness: true
  validates :organizations, length: { minimum: 2, maximum: 10 }


  def belong_to?(oid)
    organization(oid).present?
  end

  def organization(oid)
    organizations.find oid
  end

  def multi_organizations?
    organizations.count > 1
  end
end
