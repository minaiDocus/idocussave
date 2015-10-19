# -*- encoding : UTF-8 -*-
class UpdateCustomerService
  def initialize(customer, params)
    @customer = customer
    @params   = params
  end

  def execute
    previous_group_ids = @customer.groups.map(&:id)
    @customer.assign_attributes(@params)
    if @customer.valid?
      if @customer.email_changed?
        token, encrypted_token = Devise.token_generator.generate(User, :reset_password_token)
        @customer.reset_password_token = encrypted_token
        @customer.reset_password_sent_at = Time.now
        @customer.save
        WelcomeMailer.welcome_customer(@customer, token).deliver
      end
      DropboxImportFolder.changed(@customer) if @customer.company_changed?
      if previous_group_ids.sort != @customer.group_ids.sort
        groups = Group.find (previous_group_ids + @customer.group_ids)
        collaborators = groups.map(&:collaborators).flatten
        DropboxImportFolder.changed(collaborators)
      end
    end
    @customer.save
  end
end
