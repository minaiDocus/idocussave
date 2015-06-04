class CustomFileNameService
  def initialize(file_naming_policy)
    @file_naming_policy = file_naming_policy
  end

  def execute(params)
    name = ''
    options = get_options(@file_naming_policy, params)
    options.each do |option|
      name += option[0]
      name += @file_naming_policy.separator unless option == options.last
    end
    name += params['extention']
    name
  end

  def get_options(file_naming_policy, params)
    options = []
    options << [params['user_code'], file_naming_policy.first_user_identifier_position] if file_naming_policy.first_user_identifier == 'Code client iDocus'
    options << [params['user_name'], file_naming_policy.first_user_identifier_position] if file_naming_policy.first_user_identifier == 'Nom du client'
    options << [params['user_code'], file_naming_policy.second_user_identifier_position] if file_naming_policy.second_user_identifier == 'Code client iDocus'
    options << [params['user_name'], file_naming_policy.second_user_identifier_position] if file_naming_policy.second_user_identifier == 'Nom du client'
    options << [params['journal'], file_naming_policy.journal_position] if file_naming_policy.is_journal_used == 'Oui'
    options << [params['period'], file_naming_policy.period_position] if file_naming_policy.is_period_used == 'Oui'
    options << [params['piece_number'], file_naming_policy.piece_number_position] if file_naming_policy.is_piece_number_used == 'Oui'
    options << [params['third_party'], file_naming_policy.third_party_position] if file_naming_policy.is_third_party_used == 'Oui'
    options << [params['invoice_number'], file_naming_policy.invoice_number_position] if file_naming_policy.is_invoice_number_used == 'Oui'
    options << [params['invoice_date'], file_naming_policy.invoice_date_position] if file_naming_policy.is_invoice_date_used == 'Oui'
    options.sort_by!{|o, p| p}
  end
end
