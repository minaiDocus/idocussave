class IbizaAPI::Utils
  def self.description(preseizure, fields, separator)
    used_fields = { 'operation_label' => { 'is_used' => true, 'position' => 1 } }

    used_fields.merge!(fields.select { |_k, v| v['is_used'].to_i == 1 || v['is_used'] == true })

    sorted_used_fields = used_fields.sort { |(_ak, av), (_bk, bv)| av['position'].to_i <=> bv['position'].to_i }

    results = sorted_used_fields.map do |k, _|
      if k == 'journal'
        preseizure.report.journal
      elsif k == 'piece_name' && preseizure.piece
        preseizure.piece.name
      elsif k == 'piece_number'
        preseizure.piece_number
      elsif k == 'date' && preseizure[k]
        preseizure.date.in_time_zone('Paris').to_date.to_s
      else
        preseizure[k].presence
      end
    end.compact

    if results.empty?
      preseizure.third_party.presence
    else
      results.compact.join(separator)
    end
  end


  def self.piece_name(name, format, separator)
    data = name.split(' ')

    used_fields = format.select { |_k, v| v['is_used'].to_i == 1 || v['is_used'] == true }

    sorted_used_fields = used_fields.sort { |(_ak, av), (_bk, bv)| av['position'] <=> bv['position'] }

    results = sorted_used_fields.map do |key, _|
      case key
      when 'code'    then data[0]
      when 'code_wp' then data[0].match('%') ? data[0].split('%')[1] : data[0]
      when 'journal' then data[1]
      when 'period'  then data[2]
      when 'number'  then data[3]
      end
    end

    results.empty? ? name : results.compact.join(separator)
  end


  def self.to_import_xml(exercise, preseizures, fields = {}, separator = ' - ', piece_name_format = {}, piece_name_format_sep = ' ')
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.importEntryRequest do
        xml.importDate exercise.end_date
        xml.wsImportEntry do
          preseizures.each do |preseizure|
            preseizure.accounts.each do |account|
              xml.importEntry do
                xml.journalRef preseizure.report.journal
                xml.date computed_date(preseizure, exercise)

                if preseizure.piece
                  xml.piece piece_name(preseizure.piece.name, piece_name_format, piece_name_format_sep)
                  xml.voucherID "https://my.idocus.com"+ preseizure.piece.get_access_url
                  xml.voucherRef preseizure.piece_number
                else
                  xml.piece preseizure.operation_name
                end

                xml.accountNumber account.number
                xml.accountName account.number
                xml.term computed_deadline_date(preseizure, exercise) if preseizure.deadline_date.present?

                info = description(preseizure, fields, separator)
                begin
                  xml.description info
                rescue ArgumentError => e
                  if e.message == 'string contains null byte'
                    xml.description info.gsub("\u0000", '')
                  else
                    raise
                  end
                end

                entry = account.entries.first

                if entry.type == Pack::Report::Preseizure::Entry::DEBIT
                  xml.debit entry.amount
                else
                  xml.credit entry.amount
                end
              end
            end
          end
        end
      end
    end

    builder.to_xml
  end


  def self.computed_date(preseizure, exercise)
    date = preseizure.date.try(:to_date)

    if preseizure.is_period_range_used
      out_of_period_range = begin
                              date < preseizure.period_start_date || preseizure.period_end_date < date
                            rescue
                              true
                            end
    end

    result = if (preseizure.is_period_range_used && out_of_period_range) || date.nil?
               preseizure.period_start_date
             else
               date
             end

    if result < exercise.start_date && result.beginning_of_month == exercise.start_date.beginning_of_month
      exercise.start_date
    elsif exercise.next.nil? && result > exercise.end_date && result.beginning_of_month == exercise.end_date.beginning_of_month
      exercise.end_date
    else
      result
    end
  end


  def self.computed_deadline_date(preseizure, exercise)
    if preseizure.deadline_date.present?
      date = computed_date(preseizure, exercise)
      result = preseizure.deadline_date < date ? date : preseizure.deadline_date
      result.to_date
    end
  end
end
