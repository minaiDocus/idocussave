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

    def clear_string(str, replacement = '_')
      str = str.gsub(/[^a-z0-9_.éèàçôêîù:\/]/i, replacement.to_s)
      str = str.gsub(/#{replacement.to_s}+/, replacement.to_s) if replacement.present?

      str
    end

    def add_chmod_access_into(nfs_directory, type=0777)
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

    def mktmpdir(from, specific_dir=nil, with_remove=true)
      default_tmp_dir = Rails.root.join("tmp")

      final_dir = specific_dir || default_tmp_dir

      begin
        add_chmod_access_into(final_dir)
        final_dir = File.join(final_dir, Time.now.strftime("%Y%m%d%H%M%s_#{SecureRandom.alphanumeric}"))
        FileUtils.mkdir_p final_dir
        add_chmod_access_into(final_dir)

        yield(final_dir) if block_given?

        FileUtils.delay_for(rand(2..10).minutes, queue: :low).remove_entry(final_dir, true) if block_given? && with_remove && final_dir
      rescue => e
        log_document = {
          subject: "[CustomUtils] error on tmp dir creation",
          name: "CustomTempDir",
          error_group: "[CustomTempDir] error on tmp dir creation",
          erreur_type: "temp dir error creation",
          date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%s'),
          more_information: {
            from: from.to_s,
            final_dir: final_dir,
            error: e.to_s,
          }
        }

        ErrorScriptMailer.error_notification(log_document).deliver
      end

      final_dir
    end

    def is_manual_paper_set_order?(organization)
      ### ADD ORGANIZATION CODE INTO ARRAY FOR MANUAL PAPER SET ORDER ###
      ### EXAMPLE: ["IDOC", 'ORGCODE1', "ORGCODE2"].include?(organization.code)

      ["IDOC", "MCN", "CEN"].include?(organization.code)
    end
  end
end