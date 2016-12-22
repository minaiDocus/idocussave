module Account::OrganizationHelper
  def collaborator_form_url(organization, collaborator)
    if action_name == 'new' || !collaborator.persisted?
      account_organization_collaborators_url(organization)
    else
      account_organization_collaborator_url(organization, collaborator)
    end
  end


  def customer_form_url(organization, customer)
    if action_name == 'new' || !customer.persisted?
      account_organization_customers_url(organization)
    else
      account_organization_customer_url(organization, customer)
    end
  end


  def customer_address_form_url(organization, customer, address)
    if action_name == 'new' || !address.persisted?
      account_organization_customer_addresses_path(organization, customer)
    else
      account_organization_customer_address_url(organization, customer, address)
    end
  end


  def journal_form_url(organization, customer, journal)
    if action_name == 'new' || !journal.persisted?
      if customer
        account_organization_customer_journals_url(organization, customer)
      else
        account_organization_journals_url(organization)
      end
    else
      if customer
        account_organization_customer_journal_url(organization, customer, journal)
      else
        account_organization_journal_url(organization, journal)
      end
    end
  end


  def exercise_form_url(organization, customer, exercise)
    if action_name == 'new' || !exercise.persisted?
      account_organization_customer_exercises_url(organization, customer)
    else
      account_organization_customer_exercise_url(organization, customer, exercise)
    end
  end


  def description_keys(ibiza)
    if ibiza
      used_fields = ibiza.description.select { |_k, v| v['is_used'].to_i == 1 || v['is_used'] == true }

      sorted_used_fields = used_fields.sort { |(_ak, av), (_bk, bv)| av['position'] <=> bv['position'] }
      
      keys = sorted_used_fields.map { |k, _| k }
      keys.empty? ? [:third_party] : keys
    else
      [:third_party]
    end
  end
end
