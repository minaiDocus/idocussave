# frozen_string_literal: true

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

  def organization_invoice_path(invoice_id, organization_id = nil)
    unless organization_id.nil?
      return "/account/organizations/#{organization_id}/invoices/download/#{invoice_id}"
    end

    "#{download_account_organization_invoices_path}/#{invoice_id}"
  end
end
