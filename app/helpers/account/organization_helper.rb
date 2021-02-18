# frozen_string_literal: true

module Account::OrganizationHelper
  def default_banking_provider_options_for_select
    [
      ['Bridge', 'bridge'],
      ['Budget Insight', 'budget_insight']
    ]
  end

  def collaborator_form_url(organization, member)
    if action_name == 'new' || !member.persisted?
      account_organization_collaborators_url(organization)
    else
      account_organization_collaborator_url(organization, member)
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
    if action_name == 'new' || !journal.try(:persisted?)
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

  def guest_collaborator_form_url(organization, guest)
    if action_name == 'new' || !guest.persisted?
      account_organization_guest_collaborators_url(organization)
    else
      account_organization_guest_collaborator_url(organization, guest)
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

  def inside_organization?
    request.path =~ /organizations/ && !((controller_name == 'organizations' && action_name.in?(%w[index new create])) || controller_name == 'group_organizations')
  end

  def preseizure_date_options(with_organization_option = false)
    options = with_organization_option ? [[t('activerecord.models.user_options.attributes.preseizure_date_option_organization'), -1]] : []

    UserOptions::PRESEIZURE_DATE_OPTIONS.each_with_index do |type, index|
      options << [t("activerecord.models.user_options.attributes.#{type}"), index]
    end

    options
  end

  def debit_mandate_countries
    [
      %w[Allemagne DE],
      %w[Autriche AT],
      %w[Belgique BE],
      %w[Bulgarie BG],
      %w[Chypre CY],
      %w[Danemark DK],
      %w[Espagne ES],
      %w[Estonie EE],
      %w[Finlande FI],
      %w[France FR],
      %w[Gibraltar GI],
      %w[Grêce GR],
      %w[Guadeloupe GP],
      ['Guyane Française', 'GF'],
      %w[Hungary HU],
      %w[Irlande IE],
      %w[Islande IS],
      %w[Italie IT],
      %w[Lettonie LV],
      %w[Liechtenstein LI],
      %w[Lituanie LT],
      %w[Luxembourg LU],
      %w[Malte MT],
      %w[Martinique MQ],
      %w[Monaco MC],
      %w[Norvège NO],
      %w[Pays-Bas NL],
      %w[Pologne PL],
      %w[Portugal PT],
      %w[Roumanie RO],
      %w[Royaume-Uni GB],
      ['République Tchêque', 'CZ'],
      %w[Réunion RE],
      %w[Slovaquie SK],
      %w[Slovénie SI],
      %w[Suisse CH],
      %w[Suède SE],
      ['Iles Aland', 'AX']
    ]
  end
end
