# -*- encoding : UTF-8 -*-
class DeactivateOrganization
  def initialize(organization_id)
    @organization = Organization.find organization_id
  end

  def execute
    @organization.collaborators.each do |collaborator|
      CloseCollaboratorAccount.new(collaborator).execute
    end
    @organization.customers.each do |customers|
      StopSubscriptionService.new(customers, true).execute
    end
    @organization.remote_files.destroy_all
    @organization.reminder_emails.destroy_all
    @organization.knowings.try(:destroy)
    @organization.file_sending_kit.try(:destroy)
    @organization.gray_label.try(:destroy)
    @organization.file_naming_policy.try(:destroy)
    @organization.temp_documents.each do |temp_document|
      path = temp_document.content.path
      FileUtils.rm path if File.exist?(path)
    end
  end
  handle_asynchronously :execute, priority: 5
end
