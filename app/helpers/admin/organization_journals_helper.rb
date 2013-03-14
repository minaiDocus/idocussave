module Admin::OrganizationJournalsHelper
  def organization_journal_form_url(organization, journal)
    if action_name == 'new' || !journal.persisted?
      admin_organization_journals_url(organization)
    else
      admin_organization_journal_url(organization, journal)
    end
  end
end