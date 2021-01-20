class CustomUtils

  class << self
    def replace_code_of(code) #replace old code 'AC0162' with 'MVN%GRHCONSULT'
      if code.match(/^AC0162/)
        code.gsub('AC0162', 'MVN%GRHCONSULT')
      elsif code.match(/^MFA[%]ADAPTO/)
        code.gsub('MFA%ADAPTO', 'ACC%0455')
      else
        code
      end
    end

    def manual_scans_codes
      ['AC0162', 'MFA%ADAPTO']
    end

    def add_chmod_access_into(type=0777, nfs_directory)
      FileUtils.chmod(type, nfs_directory)
    end

    def customize_file_name(file_naming_policy, options)
      options = options.with_indifferent_access

      data = []

      data << [options['user_code'],    file_naming_policy.first_user_identifier_position]  if file_naming_policy.first_user_identifier == 'code'
      data << [options['user_company'], file_naming_policy.first_user_identifier_position]  if file_naming_policy.first_user_identifier == 'company'

      data << [options['user_code'],    file_naming_policy.second_user_identifier_position] if file_naming_policy.second_user_identifier == 'code'
      data << [options['user_company'], file_naming_policy.second_user_identifier_position] if file_naming_policy.second_user_identifier == 'company'

      data << [options['period'],  file_naming_policy.period_position]  if file_naming_policy.is_period_used
      data << [options['journal'], file_naming_policy.journal_position] if file_naming_policy.is_journal_used

      data << [options['third_party'],  file_naming_policy.third_party_position]  if file_naming_policy.is_third_party_used
      data << [options['piece_number'], file_naming_policy.piece_number_position] if file_naming_policy.is_piece_number_used

      data << [options['invoice_date'],   file_naming_policy.invoice_date_position]   if file_naming_policy.is_invoice_date_used
      data << [options['invoice_number'], file_naming_policy.invoice_number_position] if file_naming_policy.is_invoice_number_used

      file_name = data.sort_by(&:last)
                      .map(&:first)
                      .compact
                      .map(&:strip)
                      .join(file_naming_policy.separator)
                      .gsub(/\s*(\/|\||\\|:|&)+\s*/, file_naming_policy.separator)
                      .gsub(/\s+/, file_naming_policy.separator)

      file_name + options['extension']
    end

    def mktmpdir(specific_dir=nil, with_remove=true)
      rails_env = Rails.env == "production"
      add_chmod_access_into("/nfs/tmp/") if rails_env

      specific_dir = Rails.root.join("tmp", "#{Time.now.strftime('%Y%m%d%H%M%s')}") if !rails_env

      dir = (specific_dir.nil? && rails_env) ? File.join("/nfs/tmp/", "#{Time.now.strftime('%Y%m%d%H%M%s')}") : File.join(specific_dir)
      FileUtils.mkdir_p dir

      add_chmod_access_into(dir) if rails_env

      yield(dir)

      FileUtils.remove_entry dir if with_remove && dir

      dir
    end
  end
end