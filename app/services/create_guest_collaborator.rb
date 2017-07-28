class CreateGuestCollaborator
  def initialize(params, organization)
    @params = params
    @organization = organization
  end

  def execute
    guest = User.new(@params)
    guest.organization  = @organization
    guest.is_guest = true
    guest.set_random_password

    if guest.save
      token, encrypted_token = Devise.token_generator.generate(User, :reset_password_token)
      guest.reset_password_token = encrypted_token
      guest.reset_password_sent_at = Time.now
      guest.save

      WelcomeMailer.welcome_guest_collaborator(guest, token).deliver_later
    end

    guest
  end
end
