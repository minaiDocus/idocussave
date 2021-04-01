class OrganizationGroup < ApplicationRecord
  has_and_belongs_to_many :organizations

  validates :name, presence: true, uniqueness: true
  validates :organizations, length: { minimum: 2, maximum: 10 }


  def belong_to?(oid)
    get_organization(oid).present?
  end

  def get_organization(oid)
    organizations.where(id: oid).first
  end

  def multi_organizations?
    organizations.count > 1
  end
end
