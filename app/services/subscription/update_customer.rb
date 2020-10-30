# -*- encoding : UTF-8 -*-
# Service for generic customer update
class Subscription::UpdateCustomer
  def initialize(customer, params)
    @params   = params
    @customer = customer
  end

  def execute
    previous_group_ids = @customer.groups.pluck(:id)

    @customer.assign_attributes(@params)

    if @customer.valid?
      # If customer email has changed, we force a password reset
      if @customer.email_changed?
        token, encrypted_token = Devise.token_generator.generate(User, :reset_password_token)

        @customer.reset_password_token   = encrypted_token
        @customer.reset_password_sent_at = Time.now
        @customer.save

        WelcomeMailer.welcome_customer(@customer, token).deliver_later
      end

      # Regenerate dropbox mapping to keep link with other users
      FileImport::Dropbox.changed(@customer) if @customer.company_changed?

      # Regenerate dropbox mapping to keep link with other users in case of group change
      if previous_group_ids.sort != @customer.group_ids.sort
        groups = Group.find (previous_group_ids + @customer.group_ids)
        FileImport::Dropbox.changed(groups.flat_map(&:collaborators))
      end
    end

    @customer.save
  end
end
