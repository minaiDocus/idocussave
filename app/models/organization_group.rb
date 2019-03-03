class OrganizationGroup < ApplicationRecord
  has_many :organizations

  validates :name, presence: true, uniqueness: true
  validates :organizations, length: { minimum: 2, maximum: 10 }
end
