module IbizaLib
  module Api
    class Utils
      class << self
        def description(preseizure, fields, separator)
          used_fields = { 'operation_label' => { 'is_used' => true, 'position' => 1 } }

          used_fields.merge!(fields.select { |_k, v| v['is_used'].to_i == 1 || v['is_used'] == true })

          sorted_used_fields = used_fields.sort { |(_ak, av), (_bk, bv)| av['position'].to_i <=> bv['position'].to_i }

          results = sorted_used_fields.map do |k, _|
            if k == 'journal'
              preseizure.journal_name
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


        def piece_name(name, format, separator)
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


        def to_import_xml(exercise, preseizures, ibiza=nil, force=false)
          fields                      = ibiza.try(:description).presence || {}
          separator                   = ibiza.try(:description_separator).presence || ' - '
          piece_name_format           = ibiza.try(:piece_name_format).presence || {}
          piece_name_format_sep       = ibiza.try(:piece_name_format_sep).presence || ' '
          voucher_ref_target          = ibiza.try(:voucher_ref_target).presence || 'piece_number'
          preseizures_to_deliver_size = 0

          builder = Nokogiri::XML::Builder.new do |xml|
            xml.importEntryRequest do
              xml.importDate exercise.end_date
              xml.wsImportEntry do
                preseizures.each do |preseizure|
                  date = preseizure.computed_date exercise
                  if !force && (preseizure.pre_assignment_deliveries.sent.size > 0 || IbizaLib::PreseizureFinder.is_delivered?(preseizure, date))
                    preseizure.delivered_to('ibiza')
                    preseizure.set_delivery_message_for('ibiza', 'already sent')
                    preseizure.save
                    next
                  end

                  preseizures_to_deliver_size += 1
                  preseizure.accounts.each do |account|
                    xml.importEntry do
                      xml.journalRef preseizure.journal_name
                      xml.date date

                      if preseizure.piece
                        case voucher_ref_target
                          when 'piece_name'
                            xml.piece preseizure.piece_number
                            xml.voucherRef piece_name(preseizure.piece.name, piece_name_format, piece_name_format_sep)
                          else
                            xml.piece piece_name(preseizure.piece.name, piece_name_format, piece_name_format_sep)
                            xml.voucherRef preseizure.piece_number
                        end

                        _temp_document = preseizure.piece.temp_document
                        if _temp_document.try(:delivered_by) == 'ibiza' && _temp_document.try(:api_id).present?
                          xml.voucherID "ibiza:#{_temp_document.api_id}"
                        else
                          xml.voucherID "https://my.idocus.com"+ preseizure.piece.get_access_url
                        end
                      else
                        case voucher_ref_target
                          when 'piece_name'
                            xml.voucherRef preseizure.operation_name
                          else
                            xml.piece preseizure.operation_name
                        end
                      end

                      xml.accountNumber account.number
                      xml.accountName account.number
                      xml.term preseizure.computed_deadline_date(exercise) if preseizure.deadline_date.present?

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

                      if account.type == Pack::Report::Preseizure::Account::HT && preseizure.analytic_reference.present?
                        xml.importAnalyticalEntries do
                          3.times do |e|
                            i = e+1
                            if preseizure.analytic_reference.send("a#{i}_name").present? && preseizure.analytic_reference.send("a#{i}_references").present?
                              references = JSON.parse(preseizure.analytic_reference.send("a#{i}_references"))

                              3.times do |j|
                                next if !references[j]['axis1'].present? && !references[j]['axis2'].present? && !references[j]['axis3'].present?

                                ventilation_rate = references[j]['ventilation'].to_f || 0

                                xml.importAnalyticalEntry do
                                  xml.analysis preseizure.analytic_reference.send("a#{i}_name")
                                  xml.axis1    references[j]['axis1'].presence
                                  xml.axis2    references[j]['axis2'].presence
                                  xml.axis3    references[j]['axis3'].presence
                                  if entry.type == Pack::Report::Preseizure::Entry::DEBIT
                                    xml.debit entry.amount * (ventilation_rate / 100)
                                  else
                                    xml.credit entry.amount * (ventilation_rate / 100)
                                  end
                                end
                              end
                            end
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
          end

          return { data_count: preseizures_to_deliver_size, data_built: builder.to_xml }
        end
      end
    end
  end
end