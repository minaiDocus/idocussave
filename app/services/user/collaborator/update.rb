class User::Collaborator::Update
  def initialize(member, params)
    @member = member
    @params = params
  end

  def execute
    @member.assign_attributes(@params)
    is_email_changed = @member.user.email_changed?

    if @member.save
      if is_email_changed
        token, encrypted_token = Devise.token_generator.generate(User, :reset_password_token)

        @member.user.reset_password_token   = encrypted_token
        @member.user.reset_password_sent_at = Time.now
        @member.user.save

        WelcomeMailer.welcome_collaborator(@member.user, token).deliver_later
      end
    end

    @member.valid?
  end
end
