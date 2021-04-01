class PonctualScripts::MigrateOrganizationGroupToOrganizationGroupsOrganizations < PonctualScripts::PonctualScript
  def self.execute
    new().run
  end

  def self.rollback
    new().rollback
  end

  private

  def execute
    organizations = Organization.all

    organizations.each do |organization|
      next if not organization.organization_group_id
      logger_infos "[MigrateOrganizationGroupToOrganizationGroupsOrganizations] - organization_code: #{organization.code} - group : #{organization.organization_group_id} - Start"

      ActiveRecord::Base.connection.execute("INSERT INTO organization_groups_organizations (organization_id, organization_group_id) VALUES (#{organization.id}, #{organization.organization_group_id})")

      logger_infos "[MigrateOrganizationGroupToOrganizationGroupsOrganizations] - organization_code: #{organization.code} - End"
    end
  end

  def backup 
  end
end