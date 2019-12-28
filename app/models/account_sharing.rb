class AccountSharing < ApplicationRecord
  belongs_to :organization, optional: true
  belongs_to :collaborator,  class_name: 'User', optional: true
  belongs_to :account,       class_name: 'User', optional: true
  belongs_to :authorized_by, class_name: 'User', optional: true

  validates_presence_of :organization, :collaborator, :account
  validate :type_of_collaborator
  validate :type_of_account
  validate :uniqueness_of_sharing

  scope :approved, -> { where(is_approved: true) }
  scope :pending,  -> { where(is_approved: false) }

  default_scope -> { where(is_approved: true) }

  class << self
    def search(contains)
      account_sharings = self.all.joins(:account, :collaborator)
      account_sharings = account_sharings.where(
        "users.code REGEXP :t OR "\
        "users.company REGEXP :t OR "\
        "users.first_name REGEXP :t OR "\
        "users.last_name REGEXP :t",
        t: contains[:account].split.join('|')) if contains[:account].present?
      account_sharings = account_sharings.where(
        "collaborators_account_sharings.email REGEXP :t OR "\
        "collaborators_account_sharings.code REGEXP :t OR "\
        "collaborators_account_sharings.company REGEXP :t OR "\
        "collaborators_account_sharings.first_name REGEXP :t OR "\
        "collaborators_account_sharings.last_name REGEXP :t",
        t: contains[:collaborator].split.join('|')) if contains[:collaborator].present?

      if contains[:created_at].present?
        account_sharings = account_sharings.where("account_sharings.created_at <= ?", contains[:created_at]['<=']) if contains[:created_at]['<='].present?
        account_sharings = account_sharings.where("account_sharings.created_at >= ?", contains[:created_at]['>=']) if contains[:created_at]['>='].present?
      end

      account_sharings = account_sharings.where(is_approved: (contains[:is_approved] == '1' ? true : false)) if contains[:is_approved].present?

      account_sharings
    end
  end

private

  def type_of_collaborator
    if collaborator && (collaborator.is_admin || collaborator.is_prescriber || collaborator == account || collaborator.try(:organization) != organization)
      errors.add(:collaborator_id, :invalid)
    end
  end

  def type_of_account
    if account && (account.is_admin || account.is_prescriber || account.is_guest || account == collaborator || account.try(:organization) != organization)
      errors.add(:account_id, :invalid)
    end
  end

  def uniqueness_of_sharing
    if account && collaborator
      account_sharing = AccountSharing.unscoped.where(account: account, collaborator: collaborator).first
      if account_sharing && account_sharing != self
        errors.add(:account, :taken)
        errors.add(:collaborator, :taken)
      end
    end
  end
end
