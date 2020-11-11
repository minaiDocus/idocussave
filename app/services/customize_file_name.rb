class CustomizeFileName
  def initialize(file_naming_policy)
    @policy = file_naming_policy
  end


  def execute(options)
    options = options.with_indifferent_access

    data = []

    data << [options['user_code'],       @policy.first_user_identifier_position]  if @policy.first_user_identifier == 'code'
    data << [options['user_company'], @policy.first_user_identifier_position]  if @policy.first_user_identifier == 'company'

    data << [options['user_code'],       @policy.second_user_identifier_position] if @policy.second_user_identifier == 'code'
    data << [options['user_company'], @policy.second_user_identifier_position] if @policy.second_user_identifier == 'company'

    data << [options['period'],  @policy.period_position]  if @policy.is_period_used
    data << [options['journal'], @policy.journal_position] if @policy.is_journal_used
    
    data << [options['third_party'],      @policy.third_party_position]      if @policy.is_third_party_used
    data << [options['piece_number'], @policy.piece_number_position] if @policy.is_piece_number_used
    
    data << [options['invoice_date'],     @policy.invoice_date_position]      if @policy.is_invoice_date_used
    data << [options['invoice_number'], @policy.invoice_number_position] if @policy.is_invoice_number_used

    file_name = data.sort_by(&:last)
                    .map(&:first)
                    .compact
                    .map(&:strip)
                    .join(@policy.separator)
                    .gsub(/\s*(\/|\||\\|:|&)+\s*/, @policy.separator)
                    .gsub(/\s+/, @policy.separator)

    file_name + options['extension']
  end
end
