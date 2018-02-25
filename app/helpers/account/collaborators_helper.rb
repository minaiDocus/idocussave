module Account::CollaboratorsHelper
  def organization_role_options
    [
      ['Collaborateur', Member::COLLABORATOR],
      ["Administrateur de l'organisation", Member::ADMIN]
    ]
  end
end
