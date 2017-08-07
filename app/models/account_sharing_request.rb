# TODO : need auto test
class AccountSharingRequest
  include ActiveModel::Model

  attr_accessor :user, :code_or_email

  validates :user, presence: true
  validates :code_or_email, presence: true
  validate :validity_of_account

  def save
    if valid?
      account_sharing = AccountSharing.new
      account_sharing.organization  = user.organization
      account_sharing.collaborator  = user
      account_sharing.account       = account
      account_sharing.is_approved   = false
      if account_sharing.save
        if account.parent || account.organization.leader
          notification = Notification.new
          notification.user        = account.parent || account.organization.leader
          notification.notice_type = 'account_sharing_request'
          notification.title       = "Demande d'accès à un dossier"
          notification.message     = "#{user.info} souhaite accéder au dossier #{account.info}."
          NotifyWorker.perform_async(notification.id) if notification.save
        end
        true
      end
    end
  end

private

  def account
    @account ||= user.organization.customers.where('code = :q OR email = :q', q: code_or_email).first
  end

  def validity_of_account
    errors.add(:code_or_email, :invalid) unless account && account != user
    errors.add(:code_or_email, :already_exist) if account && AccountSharing.unscoped.where(collaborator: user, account: account).first
  end
end
