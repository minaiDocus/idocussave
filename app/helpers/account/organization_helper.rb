module Account::OrganizationHelper
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

  def exercice_form_url(customer, exercice)
    if action_name == 'new' || !exercice.persisted?
      account_organization_customer_exercices_url(customer)
    else
      account_organization_customer_exercice_url(customer, exercice)
    end
  end

  def groups(user)
    if user.organization.leader == user
      user.organization.groups
    else
      user.groups
    end
  end

  def description_keys(ibiza)
    if ibiza
      used_fields = ibiza.description.select { |k,v| v['is_used'].to_i == 1 || v['is_used'] == true }
      sorted_used_fields = used_fields.sort { |(ak,av),(bk,bv)| av['position'] <=> bv['position'] }
      keys = sorted_used_fields.map { |k,_| k }
      keys.empty? ? [:third_party] : keys
    else
      [:third_party]
    end
  end
end