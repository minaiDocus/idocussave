class CreateCollaborator
  def initialize(params, organization)
    @params = params

    @organization = organization
  end


  def execute
    collaborator = User.new(@params)

    collaborator.organization  = @organization
    collaborator.is_prescriber = true

    collaborator.set_random_password

    if collaborator.save
      token, encrypted_token = Devise.token_generator.generate(User, :reset_password_token)

      collaborator.reset_password_token = encrypted_token
      collaborator.reset_password_sent_at = Time.now
      collaborator.save

      collaborator.create_options

      WelcomeMailer.welcome_collaborator(collaborator, token).deliver_later
    end

    collaborator
  end
end
