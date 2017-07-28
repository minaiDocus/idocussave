class AccountSharing < ActiveRecord::Base
  belongs_to :organization
  belongs_to :collaborator,  class_name: 'User'
  belongs_to :account,       class_name: 'User'
  belongs_to :requested_by,  class_name: 'User'
  belongs_to :authorized_by, class_name: 'User'

  validates_presence_of :organization, :collaborator, :account, :authorized_by
  validate :type_of_collaborator
  validate :type_of_account

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
        "collaborators_account_sharings.code REGEXP :t OR "\
        "collaborators_account_sharings.company REGEXP :t OR "\
        "collaborators_account_sharings.first_name REGEXP :t OR "\
        "collaborators_account_sharings.last_name REGEXP :t",
        t: contains[:collaborator].split.join('|')) if contains[:collaborator].present?
      account_sharings
    end
  end

private

  def type_of_collaborator
    if collaborator && (collaborator.is_admin || collaborator.is_prescriber || !collaborator.is_guest || collaborator == account || collaborator.try(:organization) != organization)
      errors.add(:collaborator_id, :invalid)
    end
  end

  def type_of_account
    if account && (account.is_admin || account.is_prescriber || account.is_guest || account == collaborator || account.try(:organization) != organization)
      errors.add(:account_id, :invalid)
    end
  end
end
