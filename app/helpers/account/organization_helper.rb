module Account::OrganizationHelper
  def is_editable?(customer, organization, groups)
    if customer.is_editable && organization.is_edit_authorized
      if groups.size == 0
        true
      else
        temp_groups = groups.select { |e| e['customer_ids'].include? customer.id }
        if temp_groups.size == 0
          true
        elsif temp_groups.size == 1
          temp_groups.first.is_edit_authorized
        else
          temp_groups.inject { |m,e| m.is_edit_authorized || e.is_edit_authorized }
        end
      end
    else
      false
    end
  end

  def collaborator_form_url(collaborator)
    if action_name == 'new' || !collaborator.persisted?
      account_organization_collaborators_url
    else
      account_organization_collaborator_url(collaborator)
    end
  end

  def customer_form_url(customer)
    if action_name == 'new' || !customer.persisted?
      account_organization_customers_url
    else
      account_organization_customer_url(customer)
    end
  end

  def customer_address_form_url(customer, address)
    if action_name == 'new' || !address.persisted?
      account_organization_customer_addresses_path(customer)
    else
      account_organization_customer_address_url(customer, address)
    end
  end

  def journal_form_url(journal)
    if action_name == 'new' || !journal.persisted?
      account_organization_journals_url
    else
      account_organization_journal_url(journal)
    end
  end
end