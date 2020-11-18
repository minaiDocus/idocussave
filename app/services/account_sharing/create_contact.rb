class AccountSharing::CreateContact
  def initialize(params, organization)
    @params = params
    @organization = organization
  end

  def execute
    contact = User.new(@params)
    contact.organization = @organization
    contact.is_guest     = true
    contact.set_random_password

    if contact.save
      contact.code = "#{@organization.code}%SHR#{contact.id}"
      token, encrypted_token = Devise.token_generator.generate(User, :reset_password_token)
      contact.reset_password_token = encrypted_token
      contact.reset_password_sent_at = Time.now
      contact.save!

      contact.create_options
      contact.create_notify

      WelcomeMailer.welcome_guest_collaborator(contact, token).deliver_later
    end

    contact
  end
end
