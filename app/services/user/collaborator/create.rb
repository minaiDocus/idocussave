class User::Collaborator::Create
  def initialize(params, organization)
    @params = params
    @organization = organization
  end

  def execute
    member = Member.new(@params)
    member.organization = @organization
    user = member.user
    user.is_prescriber = true
    user.set_random_password

    if member.save
      token, encrypted_token = Devise.token_generator.generate(User, :reset_password_token)

      user.reset_password_token = encrypted_token
      user.reset_password_sent_at = Time.now
      user.save

      user.create_options
      user.create_notify

      # Creates membership for each organization in the group
      @organization.organization_groups.each do |organization_group|
        if organization_group.is_auto_membership_activated
          base_code = "#{@organization.code}%"
          organization_group.organizations.each do |organization|
            next if organization == @organization

            new_base_code = "#{organization.code}%"
            Member.create(
              user: user,
              organization: organization,
              role: member.role,
              code: member.code.sub(/^#{base_code}/, new_base_code)
            )
          end
        end
      end

      WelcomeMailer.welcome_collaborator(user, token).deliver_later
    end

    member
  end
end
