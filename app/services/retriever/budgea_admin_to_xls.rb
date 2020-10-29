# -*- encoding : UTF-8 -*-
class Retriever::BudgeaAdminToXls
  def execute(export_type='data')
    accounts              = BudgeaAccount.where.not(encrypted_access_token: nil)
    list_retriever_budgea = []
    body_csv_normal       = []
    body_csv_failed       = []
    body_csv_bug          = []

    call_counter = 0
    accounts.each do |account|
      if call_counter > 25
        call_counter = 0
        sleep(10)
      end

      access_token   = account.access_token
      account_active = account.user.still_active?
      client         = Budgea::Client.new(access_token)

      response       = client.get_all_connections
      call_counter   += 1
      sleep(3)

      begin
        json_content = response.with_indifferent_access
      rescue
        next
      end

      next if json_content['connections'].nil?

      json_content['connections'].each do |connection|
        id_connection = connection['id']
        response      = client.get_connections_log(id_connection)
        call_counter   += 1
        sleep(4)

        last_logs = response.try(:[], 'connectionlogs')
        retriever_logs = ''

        if last_logs.any?
          5.times do |i|
            begin
              log = last_logs[i]

              if log.present?
                retriever_logs += "#{i} ==> "
                ['id', 'timestamp', 'error', 'error_message', 'statut', 'start', 'id_user', 'id_connector', 'id_source', 'next_try'].each do |key|
                  retriever_logs += "#{key.to_s}=>#{log[key.to_s]}, "
                end
                retriever_logs += "\n"
              end
            rescue => e
              retriever_logs += "#{i} ==> #{e.to_s} \n"
            end
          end
        else
          retriever_logs = response.to_s
        end

        list_retriever_budgea << id_connection

        retriever = Retriever.where(budgea_id: id_connection).first

        if retriever.present?
          state             = retriever.state
          retriever_state   = retriever.budgea_state
          retriever_message = retriever.budgea_error_message

          body_csv_normal << [account.user.code, account_active, retriever.id, id_connection, retriever.name, retriever.journal_name, account.identifier, access_token, state, retriever_state, retriever_message, retriever_logs.to_s.strip ]
        else
          body_csv_failed << [account.user.code, account_active, '', id_connection, '', '', account.identifier, access_token, '', '', '', retriever_logs.to_s.strip ]
        end
      end

    end
    list_retriever_budgea.uniq! if list_retriever_budgea.any?

    body_csv_bug = verify_retriever_idocus_and_not_at_budgea_with list_retriever_budgea if list_retriever_budgea.any?

    if export_type == 'data'
      for_export(body_csv_normal, body_csv_failed, body_csv_bug)
    elsif export_type == 'file'
      file = File.open(Rails.root.join('files', 'retrievers_export.xls'), 'w')
      file.write for_export(body_csv_normal, body_csv_failed, body_csv_bug).to_s.force_encoding('UTF-8')
      file.close

      file.path.to_s
    else
      { normal: body_csv_normal, failed: body_csv_failed, bug: body_csv_bug }
    end
  end

  private

  def for_export(body_csv_normal, body_csv_failed, body_csv_bug)
    book = Spreadsheet::Workbook.new

    sheet1 = book.create_worksheet name: 'Normal'
    sheet2 = book.create_worksheet name: 'Failed'
    sheet3 = book.create_worksheet name: 'Bug'

    headers = []
    headers += ['User code', 'User active?', 'ID', 'ID Connexion', 'Nom retriever', 'Journal retriever', 'User identifier', 'Access token', 'Etat', 'Etat distant', 'Message', 'Logs']

    insert_book(headers, sheet1, body_csv_normal)
    insert_book(headers, sheet2, body_csv_failed)
    insert_book(headers, sheet3, body_csv_bug)

    io = StringIO.new('')
    book.write(io)
    io.string
  end

  def insert_book(headers, sheet, body_csv)
    sheet.row(0).concat headers

    body_csv.each_with_index do |data, index|
      sheet.row(index + 1).replace(data)
    end
  end

  def verify_retriever_idocus_and_not_at_budgea_with(list_retriever_budgea)
    retrievers = Retriever.where.not(budgea_id: list_retriever_budgea)
    body_csv   = []

    if retrievers
      retrievers.each do |retriever|
        state             = retriever.state
        retriever_state   = retriever.budgea_state
        retriever_message = retriever.budgea_error_message
        user              = retriever.user

        body_csv << [user.code, user.still_active?, retriever.id, retriever.budgea_id, retriever.name, retriever.journal_name, user.budgea_account.try(:identifier), user.budgea_account.try(:access_token), state, retriever_state, retriever_message, '' ]
      end
    end

    body_csv
  end
end