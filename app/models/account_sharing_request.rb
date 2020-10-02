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
        collaborators = if account.manager&.user
          [account.manager.user]
        else
          account.organization.admins
        end

        collaborators.each do |collaborator|
          url = Rails.application.routes.url_helpers.account_organization_account_sharings_url(
           account.organization,
           ActionMailer::Base.default_url_options
          )

          Notifications::Notifier.new.create_notification({
            url: url,
            user: collaborator,
            notice_type: 'account_sharing_request',
            title: "Demande d'accès à un dossier",
            message: "#{user.info} souhaite accéder au dossier #{account.info}."
          }, true)
        end
        true
      end
    else
      false
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
