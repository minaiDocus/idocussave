class UpdateCollaborator
  def initialize(collaborator, params)
    @params       = params
    @collaborator = collaborator
  end


  def execute
    @collaborator.assign_attributes(@params)

    is_email_changed = @collaborator.email_changed?

    if @collaborator.save
      if is_email_changed
        token, encrypted_token = Devise.token_generator.generate(User, :reset_password_token)

        @collaborator.reset_password_token   = encrypted_token
        @collaborator.reset_password_sent_at = Time.now

        @collaborator.save

        WelcomeMailer.welcome_collaborator(@collaborator, token).deliver_later
      end
    end

    @collaborator
  end
end
