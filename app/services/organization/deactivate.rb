class Organization::Deactivate
  def initialize(organization_id)
    @organization = Organization.find organization_id
  end

  def execute
    @organization.collaborators.each do |collaborator|
      User::Collaborator::CloseAccount.new(collaborator).execute
    end

    @organization.customers.each do |customer|
      next unless customer.active?
      Subscription::Stop.new(customer, false).execute
    end

    @organization.reminder_emails.destroy_all
    @organization.ibiza.try(:destroy)
    @organization.knowings.try(:destroy)
    @organization.mcf_settings.try(:destroy)
    @organization.file_sending_kit.try(:destroy)
    @organization.file_naming_policy.try(:destroy)
  end
end
