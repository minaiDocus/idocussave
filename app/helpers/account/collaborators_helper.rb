module Account::CollaboratorsHelper
  def organization_role_options
    [
      ['Collaborateur', Member::COLLABORATOR],
      ["Administrateur de l'organisation", Member::ADMIN]
    ]
  end

  def accessible_organizations_for_user(user)
    organizations = @organization.organization_group&.organizations || []
    organizations += user.organizations.to_a
    organizations.uniq.sort_by(&:name)
  end
end
