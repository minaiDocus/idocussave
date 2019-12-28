class Member < ApplicationRecord
  include ::CodeFormatValidation

  ADMIN        = 'admin'.freeze
  COLLABORATOR = 'collaborator'.freeze
  ROLES        = [ADMIN, COLLABORATOR].freeze

  audited

  belongs_to :organization, optional: true
  belongs_to :user, optional: true
  has_many :managed_users, class_name: 'User', inverse_of: :manager
  has_and_belongs_to_many :groups
  has_many :grouped_customers, -> { distinct }, through: :groups, source: :customers

  validates_inclusion_of :role, in: ROLES
  validates :code, presence: true, length: { within: 3..15 }
  validate :uniqueness_of_code

  accepts_nested_attributes_for :user

  scope :admins,        -> { where(role: ADMIN) }
  scope :collaborators, -> { where(role: COLLABORATOR) }

  def admin?
    role == ADMIN
  end

  def collaborator?
    role == COLLABORATOR
  end

  def name
    user.name
  end

  def info
    [code, user.company, user.name].reject(&:blank?).join(' - ')
  end

  def to_param
    [id, user.company.parameterize].join('-')
  end

  def customers
    if admin?
      organization.customers
    else
      grouped_customers
    end
  end

  def self.search(contains)
    members = self.all.joins(:user)
    members = members.where(role: contains[:role])                                   if contains[:role].present?
    members = members.where("members.code LIKE ?",     "%#{contains[:code]}%")       if contains[:code].present?
    members = members.where("users.email LIKE ?",      "%#{contains[:email]}%")      if contains[:email].present?
    members = members.where("users.company LIKE ?",    "%#{contains[:company]}%")    if contains[:company].present?
    members = members.where("users.last_name LIKE ?",  "%#{contains[:last_name]}%")  if contains[:last_name].present?
    members = members.where("users.first_name LIKE ?", "%#{contains[:first_name]}%") if contains[:first_name].present?
    members
  end

  private

  def uniqueness_of_code
    member = Member.find_by(code: code)
    user = User.where(is_prescriber: false).find_by(code: code)
    if (member && member != self) || user
      errors.add(:code, :taken)
    end
  end
end
